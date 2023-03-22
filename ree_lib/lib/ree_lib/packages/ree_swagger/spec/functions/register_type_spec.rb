RSpec.describe :register_type do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper
  link :build_request_body_schema, from: :ree_swagger
  link :build_serializer_schema, from: :ree_swagger
  link :register_type, from: :ree_swagger

  class ReeSwagger::MyType < ReeMapper::AbstractType
    def serialize(obj, role: nil)
      obj.inspect
    end

    def cast(obj, **)
      obj
    end
  end

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :serialize, dto: Hash),
      build_mapper_strategy(method: :cast, dto: Hash),
    ]

    build_mapper_factory(strategies: strategies)
      .register_type(:my_type, ReeSwagger::MyType.new)
  }

  let(:mapper) {
    mapper_factory.call.use(:serialize).use(:cast) do
      my_type :name
      array :ids, integer
    end
  }

  before do
    register_type(
      :serializers,
      ReeSwagger::MyType,
      ->(my_type, build_serializer_schema) {
        {
          type: 'string'
        }
      }
    )

    register_type(
      :casters,
      ReeSwagger::MyType,
      ->(my_type, build_serializer_schema) {
        {
          type: 'string'
        }
      }
    )
  end

  it {
    expect(build_serializer_schema(mapper)).to eq(
      {
        type: 'object',
        properties: {
          name: {
            type: 'string'
          },
          ids: { items: { type: "integer" }, type: "array" }
        }
      }
    )
  }

  it {
    expect(build_request_body_schema(mapper)).to eq(
      {
        type: 'object',
        required: ["name", "ids"],
        properties: {
          name: {
            type: 'string'
          },
          ids: { items: { type: "integer" }, type: "array" }
        }
      }
    )
  }
end
