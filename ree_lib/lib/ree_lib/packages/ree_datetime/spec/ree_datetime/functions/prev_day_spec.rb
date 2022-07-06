# frozen_string_literal: true

RSpec.describe :prev_day do
  link :prev_day, from: :ree_datetime

  it {
    result  = prev_day(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 22, 13, 15, 10))
  }

  it {
    result = prev_day()

    expect(result).to be_a(DateTime)
  }
end