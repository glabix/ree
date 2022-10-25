# frozen_string_literal: true

class ReeSwagger::BuildRequestBodySchema
  include Ree::FnDSL

  fn :build_request_body_schema do
    link :get_caster_definition
  end

  contract(
    ReeMapper::Mapper,
    ArrayOf[Symbol],
    ArrayOf[ReeMapper::FieldsFilter] => Nilor[Hash]
  )
  def call(mapper, path_params = [], fields_filters = [])
    if mapper.type
      return get_caster_definition(mapper.type, method(:call).to_proc)
    end

    required_fields = []

    properties = mapper.fields.each_with_object({}) do |(_name, field), acc|
      next unless fields_filters.all? { _1.allow?(field.name) }

      next if path_params.include?(field.name)

      swagger_field = {}

      required_fields << field.name.to_s if !field.optional
      field_mapper = field.type

      nested_fields_filters = fields_filters.map { _1.filter_for(field.name) }
      nested_fields_filters += [field.fields_filter]

      swagger_type = call(field_mapper, [], nested_fields_filters)

      swagger_field.merge!(swagger_type) if swagger_type

      description = field.doc
      swagger_field[:description] = description if description

      swagger_field[:nullable] = true if field.null

      acc[field.name] = swagger_field
    end

    return if properties.empty?

    obj = {
      type: 'object',
      properties: properties,
    }
    obj[:required] = required_fields if required_fields.size != 0
    obj
  end
end
