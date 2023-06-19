RSpec.describe :build_request_body_schema_spec do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper
  link :build_request_body_schema, from: :ree_swagger

  let(:mapper_factory) {
    strategies = [
      build_mapper_strategy(method: :cast, dto: Hash),
    ]

    build_mapper_factory(
      strategies: strategies
    )
  }

  it {
    caster = mapper_factory.call(register_as: :user).use(:cast) do
      string :name
      string :email
      string? :last_name
      user :friend
    end

    schema = {
      type: "object",
      properties: {
        name: { type: "string" },
        email: { type: "string" },
        last_name: { type: "string" },
        friend: {}
      },
      required: ["name", "email"]
    }

    expect(build_request_body_schema(caster)).to eq(schema)
  }
end
