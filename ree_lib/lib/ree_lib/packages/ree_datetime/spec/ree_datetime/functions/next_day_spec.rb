# frozen_string_literal: true

RSpec.describe :next_day do
  link :next_day, from: :ree_datetime

  it {
    result  = next_day(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 24, 13, 15, 10))
  }

  it {
    result = next_day()

    expect(result).to be_a(DateTime)
  }
end