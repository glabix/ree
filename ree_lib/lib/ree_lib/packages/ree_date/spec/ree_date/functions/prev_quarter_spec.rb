# frozen_string_literal: true

RSpec.describe :prev_quarter do
  link :prev_quarter, from: :ree_date

  it {
    result = prev_quarter(Date.new(2020, 12, 2))
    expect(result).to eq(Date.new(2020, 9, 2))
  }

  it {
    result = prev_quarter()
    expect(result).to eq(Date.today << 3)
  }
end