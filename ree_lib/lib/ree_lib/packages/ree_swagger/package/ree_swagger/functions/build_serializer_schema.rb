# frozen_string_literal: true

class ReeSwagger::BuildSerializerSchema
  include Ree::FnDSL

  fn :build_serializer_schema do
    link :get_serializer_definition
  end

  contract(ReeMapper::Mapper, Nilor[ArrayOf[ReeMapper::FieldsFilter]] => Nilor[Hash])
  def call(mapper, fields_filters = nil)
    if mapper.type
      return get_serializer_definition(mapper.type, method(:call).to_proc)
    end

    properties = mapper.fields.each_with_object({}) do |(_name, field), acc|
      next unless fields_filters.nil? || fields_filters.all? { _1.allow?(field.name) }

      if field.type == mapper
        acc[field.name] = {}
        next
      end

      swagger_field = {}

      field_mapper = field.type

      nested_fields_filters = fields_filters&.filter_map { _1.filter_for(field.name) }

      if field.fields_filter
        nested_fields_filters = if nested_fields_filters
          nested_fields_filters + [field.fields_filter]
        else
          [field.fields_filter]
        end
      end

      swagger_type = call(field_mapper, nested_fields_filters)

      swagger_field.merge!(swagger_type) if swagger_type

      description = field.doc
      swagger_field[:description] = description if description

      swagger_field[:nullable] = true if field.null

      acc[field.name] = swagger_field
    end

    {
      type: 'object',
      properties: properties
    }
  end
end
