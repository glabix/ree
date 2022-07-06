# frozen_string_literal: true

RSpec.describe :prev_month do
  link :prev_month, from: :ree_date

  it {
    result = prev_month(Date.new(2020, 12, 2))
    expect(result).to eq(Date.new(2020, 11, 2))
  }

  it {
    result = prev_month()
    expect(result).to eq(Date.today << 1)
  }
end