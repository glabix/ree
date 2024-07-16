# frozen_string_literal: true

class ReeSwagger::BuildParameters
  include Ree::FnDSL

  fn :build_parameters do
    link :get_caster_definition
    link :build_request_body_schema
    link :wrap, from: :ree_array
  end

  ObjectPathParamError = Class.new(StandardError)
  ArrayPathParamError = Class.new(StandardError)

  contract(ReeMapper::Mapper, ArrayOf[Symbol], Bool => ArrayOf[Hash])
  def call(mapper, path_params, with_query_params)
    mapper.fields.filter_map do |_name, field|
      is_path_param = path_params.include?(field.name)

      next unless is_path_param || with_query_params

      if is_path_param
        if field.type.type.nil?
          raise ObjectPathParamError, "path parameter(#{
            field.name
          }) can not be an object"
        end

        if field.type.type.is_a?(ReeMapper::Array)
          raise ArrayPathParamError, "path parameter(#{
            field.name
          }) can not be an array"
        end
      end

      schema =  {
        name: field.name_as_str,
        in: is_path_param ? 'path' : 'query',
        required: is_path_param || !field.optional,
        schema: build_request_body_schema(field.type, [], wrap(field.fields_filter)) || {}
      }

      schema[:style] = 'deepObject' if field.type.type.nil?
      schema[:nullable] = true if field.null

      schema
    end
  end
end
