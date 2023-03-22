# frozen_string_literal: true

RSpec.describe :from_json do
  link :from_json, from: :ree_json

  it {
    expect(from_json("{\"id\":1}", symbol_keys: true)).to eq({id: 1})
  }

  it {
    result = from_json("{\":id\":{\"^o\":\"Object\"}}", mode: :object)
    expect(result[:id]).to be_a(Object)
  }

  it {
    expect{from_json("{213: \"123\"}")}.to raise_error(ReeJson::FromJson::ParseJsonError)
  }
end