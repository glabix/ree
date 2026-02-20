# frozen_string_literal: true

RSpec.describe :to_json do
  link :to_json, from: :ree_json

  it {
    expect(to_json({id: 1})).to eq("{\"id\":1}")
  }
end
