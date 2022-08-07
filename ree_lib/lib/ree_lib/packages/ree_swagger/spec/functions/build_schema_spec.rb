RSpec.describe :build_schema do
  link :build_schema, from: :ree_swagger

  it {
    schema = build_schema(
      title: 'Sample API',
      description: 'Sample API description',
      version: '0.0.1',
      endpoints: [ReeSwagger::EndpointDto.new(
        method:          :get,
        path:            '/version',
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
        paths: {
          '/version' => {
            get: {
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
