# frozen_string_literal: true

RSpec.describe :prev_quarter do
  link :prev_quarter, from: :ree_datetime

  it {
    result  = prev_quarter(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 2, 23, 13, 15, 10))
  }

  it {
    result = prev_quarter()

    expect(result).to be_a(DateTime)
  }
end