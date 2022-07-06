# frozen_string_literal: true

RSpec.describe :digit_count do
  link :digit_count, from: :ree_number

  it {
    expect(digit_count(123456)).to eq(6)
    expect(digit_count(12345.678)).to eq(5)
    expect(digit_count(BigDecimal("123456"))).to eq(6)
  }
end