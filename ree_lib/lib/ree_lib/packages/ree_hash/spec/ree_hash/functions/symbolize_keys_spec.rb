# frozen_string_literal: true

RSpec.describe :symbolize_keys do
  link :symbolize_keys, from: :ree_hash

  it {
    result = symbolize_keys({ name: "John", "age": 25, nil: "nothing"})

    expect(result).to eq({ :name => "John", :age => 25, :nil => "nothing"})
  }
end