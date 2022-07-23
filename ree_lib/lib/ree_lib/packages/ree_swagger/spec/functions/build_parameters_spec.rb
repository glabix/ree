RSpec.describe :build_parameters_spec do
  link :build_parameters, from: :ree_swagger
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :cast, output: :symbol_key_hash),
    ]

    build_mapper_factory(
      strategies: strategies
    )
  }

  it {
    caster = mapper_factory.call.use(:cast) do
      hash :id do
        string :name
      end
    end

    expect {
      build_parameters(caster, [:id], false)
    }.to raise_error(
      ReeSwagger::BuildParameters::ObjectPathParamError,
      "path parameter(id) can not be an object"
    )
  }

  it {
    caster = mapper_factory.call.use(:cast) do
      array :id, each: string
    end

    expect {
      build_parameters(caster, [:id], false)
    }.to raise_error(
      ReeSwagger::BuildParameters::ArrayPathParamError,
      "path parameter(id) can not be an array"
    )
  }
end
