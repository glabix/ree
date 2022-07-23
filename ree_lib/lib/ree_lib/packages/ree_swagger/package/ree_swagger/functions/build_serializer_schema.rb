# frozen_string_literal: true

class ReeSwagger::BuildSerializerSchema
  include Ree::FnDSL

  fn :build_serializer_schema do
    link :get_serializer_definition
  end

  contract(ReeMapper::Mapper => Nilor[Hash])
  def call(mapper)
    if mapper.type
      return get_serializer_definition(mapper.type, method(:call).to_proc)
    end

    properties = mapper.fields.each_with_object({}) do |(_name, field), acc|
      swagger_field = {}

      field_mapper = field.type
      swagger_type = call(field_mapper)
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
