# frozen_string_literal: true

RSpec.describe :build_mapper_factory do
  link :build_mapper_factory, from: :ree_mapper
  link :build_mapper_strategy, from: :ree_mapper

  it {
    result = build_mapper_factory(strategies: [
      build_mapper_strategy(method: :cast, dto: Hash)
    ])

    expect(result).to be_a(Class)
  }
end
