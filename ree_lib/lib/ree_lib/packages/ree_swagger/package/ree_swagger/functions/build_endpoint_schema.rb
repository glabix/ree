# frozen_string_literal: true

class ReeSwagger::BuildEndpointSchema
  include Ree::FnDSL

  fn :build_endpoint_schema do
    link :get_mime_type
    link :build_parameters
    link :build_request_body_schema
    link :build_serializer_schema
    link 'ree_swagger/dto/endpoint_dto', -> { EndpointDto }
    link 'ree_swagger/dto/path_dto', -> { PathDto }
  end

  METHODS_WITH_BODY = [:post, :put, :patch].freeze
  MissingCasterError = Class.new(StandardError)

  contract(EndpointDto => PathDto)
  def call(endpoint)
    path_params = []

    path = endpoint.path
      .split('/')
      .map {
        if _1.start_with?(':')
          path_param = _1[1..-1]
          path_params << path_param.to_sym
          "{#{path_param}}"
        else
          _1
        end
      }
      .join('/')

    mime_type = get_mime_type(endpoint.respond_to)

    missed_caster = path_params - endpoint.caster&.fields&.keys.to_a

    if missed_caster.any?
      raise MissingCasterError, "missing caster for path parameters #{missed_caster.inspect}"
    end

    if endpoint.caster && METHODS_WITH_BODY.include?(endpoint.method)
      parameters = build_parameters(endpoint.caster, path_params, false)

      request_body_schema = build_request_body_schema(
        endpoint.caster,
        path_params
      )

      request_body = request_body_schema && {
        content: {
          :"#{mime_type}" => {
            schema: request_body_schema
          }
        }
      }
    elsif endpoint.caster
      parameters = build_parameters(endpoint.caster, path_params, true)
    end

    request_body =
      if endpoint.caster && METHODS_WITH_BODY.include?(endpoint.method)
        request_body_schema = build_request_body_schema(
          endpoint.caster,
          path_params
        )

        request_body_schema && {
          content: {
            :"#{mime_type}" => {
              schema: request_body_schema
            }
          }
        }
      end

    response_schema = {
      description: endpoint.response_description || ''
    }

    if endpoint.serializer
      response_schema[:content] = {
        :"#{mime_type}" => {
          schema: build_serializer_schema(endpoint.serializer)
        }
      }
    end

    responses = {
      endpoint.response_status => response_schema
    }

    endpoint.errors.each do |error|
      if responses.key?(error.status)
        responses[error.status][:description] += "\n- #{error.description}"
        next
      end

      responses[error.status] = {
        description: "- #{error.description}",
      }
    end

    method_schema = {
      responses: responses
    }

    method_schema[:summary] =  endpoint.summary if endpoint.summary
    method_schema[:description] =  endpoint.description if endpoint.description
    method_schema[:tags] = endpoint.sections if endpoint.sections

    method_schema[:parameters]  = parameters   if parameters
    method_schema[:requestBody] = request_body if request_body
    method_schema[:security] = [{ ApiKeyAuth: [] }] if endpoint.authenticate

    schema = {endpoint.method => method_schema}

    PathDto.new(
      path: path,
      schema: schema
    )
  end
end
