RSpec.describe :build_schema do
  link :build_schema, from: :ree_swagger

  it {
    schema = build_schema(
      title: 'Sample API',
      description: 'Sample API description',
      version: '0.0.1',
      api_url: 'https://some-api.com/api/v1',
      endpoints: [ReeSwagger::EndpointDto.new(
        method:          :get,
        authenticate:    true,
        path:            '/version',
        respond_to:      :json,
        caster:          nil,
        serializer:      nil,
        response_status: 200,
        description:     nil,
        summary:         nil,
        errors:          []
      )]
    )

    expect(schema).to eq(
      {
        openapi: '3.0.0',
        info: {
          title: 'Sample API',
          description: 'Sample API description',
          version: '0.0.1'
        },
        components: {
          securitySchemes: {
            bearerAuth: {
              type: 'http',
              scheme: 'bearer',
              bearerFormat: 'JWT'
            }
          }
        },
        servers: [
          { url: 'https://some-api.com/api/v1' }
        ],
        paths: {
          '/version' => {
            get: {
              security: [
                {bearerAuth: []}
              ],
              responses: {
                200 => {
                  description: ''
                }
              }
            }
          }
        }
      }
    )
  }
end
