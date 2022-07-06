# frozen_string_literal: true

RSpec.describe :next_quarter do
  link :next_quarter, from: :ree_date

  it {
    result = next_quarter(Date.new(2020, 12, 2))

    expect(result).to eq(Date.new(2021, 3, 2))
  }

  it {
    result = next_quarter()
    expect(result).to eq(Date.today >> 3)
  }
end