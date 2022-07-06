# frozen_string_literal: true

RSpec.describe :build_mapper_strategy do
  link :build_mapper_strategy, from: :ree_mapper

  it {
    result = build_mapper_strategy(method: :cast, output: :symbol_key_hash)
    
    expect(result).to be_a(ReeMapper::MapperStrategy)
  }
end
