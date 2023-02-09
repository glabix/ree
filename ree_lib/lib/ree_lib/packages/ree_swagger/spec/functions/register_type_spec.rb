RSpec.describe :register_type do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper
  link :build_serializer_schema, from: :ree_swagger
  link :register_type, from: :ree_swagger

  class ReeSwagger::MyType < ReeMapper::AbstractType
    def serialize(obj, role: nil)
      obj.inspect
    end
  end

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :serialize, dto: Hash),
    ]

    build_mapper_factory(strategies: strategies).register(
      :my_type,
      ReeMapper::Mapper.build(
        strategies,
        ReeSwagger::MyType.new
      )
    )
  }

  let(:mapper) {
    mapper_factory.call.use(:serialize) do
      my_type :name
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
  end

  it {
    expect(build_serializer_schema(mapper)).to eq(
      {
        type: 'object',
        properties: {
          name: {
            type: 'string'
          }
        }
      }
    )
  }
end
