# frozen_string_literal: true

RSpec.describe :number_to_delimited do
  link :number_to_delimited, from: :ree_number

  it {
    expect(number_to_delimited(12345678)).to eq("12,345,678")
    expect(number_to_delimited("12345678")).to eq("12,345,678")
    expect(number_to_delimited(0)).to eq("0")
    expect(number_to_delimited(123)).to eq("123")
    expect(number_to_delimited(123456)).to eq("123,456")
    expect(number_to_delimited(123456.789)).to eq("123,456.789")
    expect(number_to_delimited(123456.78901)).to eq("123,456.78901")
    expect(number_to_delimited(123456789.78901)).to eq("123,456,789.78901")
    expect(number_to_delimited(0.78901)).to eq("0.78901")
    expect(number_to_delimited("0.78901")).to eq("0.78901")
    expect(number_to_delimited(123456.78)).to eq("123,456.78")

    expect(number_to_delimited(12345678, delimiter: "*")).to eq("12*345*678")
    expect(number_to_delimited(123456.789, separator: ',', delimiter: ".")).to eq("123.456,789")
    expect(number_to_delimited(123456.78, pattern: /(\d+?)(?=(\d\d)+(\d)(?!\d))/)).to eq("1,23,456.78")
  }
end