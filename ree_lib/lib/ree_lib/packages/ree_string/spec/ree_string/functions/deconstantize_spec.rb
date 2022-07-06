# frozen_string_literal: true

RSpec.describe :deconstantize do
  link :deconstantize, from: :ree_string

  it {
    expect(deconstantize('Net::HTTP')).to eq("Net")
    expect(deconstantize('::Net::HTTP')).to eq("::Net")
    expect(deconstantize('String')).to eq("")
    expect(deconstantize('::String')).to eq("")
    expect(deconstantize('')).to eq("")
  }
end