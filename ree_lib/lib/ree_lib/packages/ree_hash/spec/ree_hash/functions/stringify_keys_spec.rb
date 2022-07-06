# frozen_string_literal: true

RSpec.describe :stringify_keys do
  link :stringify_keys, from: :ree_hash

  it {
    result = stringify_keys({name: "John", "age": 25, nil: "nothing"})

    expect(result).to eq({"name" => "John", "age" => 25, "nil" => "nothing"})
  }
  
end