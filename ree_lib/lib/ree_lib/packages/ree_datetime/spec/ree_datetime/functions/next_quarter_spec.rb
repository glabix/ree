# frozen_string_literal: true

RSpec.describe :next_quarter do
  link :next_quarter, from: :ree_datetime

  it {
    result  = next_quarter(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 8, 23, 13, 15, 10))
  }

  it {
    result = next_quarter()

    expect(result).to be_a(DateTime)
  }
end