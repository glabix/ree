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
    expect(from_json("null")).to eq(nil)
  }

  it {
    expect(from_json("true")).to eq(true)
  }

  it {
    expect(from_json('"hello"')).to eq("hello")
  }

  it {
    expect(from_json("123")).to eq(123)
  }

  it {
    expect(from_json("123.456")).to eq(123.456)
  }

  it {
    expect(from_json("[1,true,\"hello\"]")).to eq([1, true, "hello"])
  }

  it {
    expect(from_json("{\"^o\":\"Object\"}", mode: :object)).to be_a(Object)
  }

  it {
    expect{from_json("{213: \"123\"}")}.to raise_error(ReeJson::FromJson::ParseJsonError)
  }

  it {
    expect { from_json(nil, mode: :strict) }.to raise_error(ReeJson::FromJson::ParseJsonError)
  }
end