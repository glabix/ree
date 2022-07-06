# frozen_string_literal: true

RSpec.describe :next_month do
  link :next_month, from: :ree_datetime

  it {
    result  = next_month(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 6, 23, 13, 15, 10))
  }

  it {
    result = next_month()

    expect(result).to be_a(DateTime)
  }
end