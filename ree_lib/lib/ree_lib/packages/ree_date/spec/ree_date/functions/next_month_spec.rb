# frozen_string_literal: true

RSpec.describe :next_month do
  link :next_month, from: :ree_date

  it {
    result = next_month(Date.new(2020, 12, 2))

    expect(result).to eq(Date.new(2021, 1, 2))
  }

  it {
    result = next_month()
    expect(result).to eq(Date.today >> 1)
  }
end