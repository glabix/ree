RSpec.describe :build_endpoint_schema do
  link :build_endpoint_schema, from: :ree_swagger
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  before :all do
    Ree.enable_irb_mode
  end

  after :all do
    Ree.disable_irb_mode
  end

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :serialize, output: :symbol_key_hash),
      build_mapper_strategy(method: :cast, output: :symbol_key_hash),
    ]

    build_mapper_factory(
      strategies: strategies
    )
  }

  it {
    module ReeSwaggerTest
      include Ree::PackageDSL

      package

      class Locales
        include ReeEnum::DSL

        enum :locales

        val :en, 0
        val :ru, 1
      end
    end

    mapper_factory.register_type(
      :locales, ReeSwaggerTest::Locales.type_for_mapper
    )

    ReeSwaggerTest::Locales.register_as_swagger_type

    serializer = mapper_factory.call.use(:serialize) do
      integer :id
    end

    _tag_caster = mapper_factory.call(register_as: :tag).use(:cast) do
      string :name
      string :value
    end

    caster = mapper_factory.call.use(:cast) do
      integer :id
      string :name
      tag    :tag
      locales :locale
    end

    schema = build_endpoint_schema(ReeSwagger::EndpointDto.new(
      method:          :post,
      path:            '/versions/:id',
      caster:          caster,
      serializer:      serializer,
      response_status: 200,
      description:     "description",
      summary:         "summary",
      errors:          [
        ReeSwagger::ErrorDto.new(
          status: 400,
          description: "1st 400 error"
        ),
        ReeSwagger::ErrorDto.new(
          status: 400,
          description: "2nd 400 error"
        ),
        ReeSwagger::ErrorDto.new(
          status: 401,
          description: "401 error"
        )
      ]
    ))

    expect(schema).to eq(ReeSwagger::PathDto.new(
      path: '/versions/{id}',
      schema: {
        post: {
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            }
          ],
          requestBody: {
            content: {
              :'application/json' => {
                schema: {
                  type: 'object',
                  properties: {
                    name: { type: 'string' },
                    tag: {
                      type: 'object',
                      properties: {
                        name: { type: 'string' },
                        value: { type: 'string' }
                      }
                    },
                    locale: {
                      type: 'string',
                      enum: ['en', 'ru']
                    }
                  }
                }
              }
            }
          },
          responses: {
            200 => {
              description: '',
              content: {
                :'application/json' => {
                  schema: {
                    type: 'object',
                    properties: {
                      id: { type: 'integer' }
                    }
                  }
                }
              }
            },
            400 => {
              description: "- 1st 400 error\n- 2nd 400 error",

            },
            401 => {
              description: "- 401 error",
            }
          },
          summary: "summary",
          description: "description",
        }
      }
    ))
  }

  it {
    caster = mapper_factory.call.use(:cast) do
      integer :id
      string :name
      hash :obj do
        string :text
        hash :point do
          integer :x
          integer :y
        end
      end
    end

    schema = build_endpoint_schema(ReeSwagger::EndpointDto.new(
      method:          :get,
      path:            '/versions/:id',
      caster:          caster,
      serializer:      nil,
      response_status: 200,
      description:     nil,
      summary:         nil,
      errors:          []
    ))

    expect(schema).to eq(ReeSwagger::PathDto.new(
      path: '/versions/{id}',
      schema: {
        get: {
          parameters: [
            {
              name: 'id',
              in: 'path',
              required: true,
              schema: { type: 'integer' }
            },
            {
              name: 'name',
              in: 'query',
              required: true,
              schema: { type: 'string' }
            },
            {
              name: 'obj',
              in: 'query',
              required: true,
              schema: {
                type: 'object',
                properties: {
                  text: { type: 'string' },
                  point: {
                    type: 'object',
                    properties: {
                      x: { type: 'integer' },
                      y: { type: 'integer' }
                    }
                  }
                }
              },
              style: 'deepObject'
            }
          ],
          responses: {
            200 => {
              description: ''
            }
          }
        }
      }
    ))
  }

  it {
    expect {
      build_endpoint_schema(ReeSwagger::EndpointDto.new(
        method:          :get,
        path:            '/versions/:id',
        caster:          nil,
        serializer:      nil,
        response_status: 200,
        description:     nil,
        summary:         nil,
        errors:          []
      ))
    }.to raise_error(
      ReeSwagger::BuildEndpointSchema::MissingCasterError,
      "missing caster for path parameters [:id]"
    )
  }

  it {
    caster = mapper_factory.call.use(:cast) do
      string :name
    end

    expect {
      build_endpoint_schema(ReeSwagger::EndpointDto.new(
        method:          :get,
        path:            '/versions/:id',
        caster:          caster,
        serializer:      nil,
        response_status: 200,
        description:     nil,
        summary:         nil,
        errors:          []
      ))
    }.to raise_error(
      ReeSwagger::BuildEndpointSchema::MissingCasterError,
      "missing caster for path parameters [:id]"
    )
  }
end
