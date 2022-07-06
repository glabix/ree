# frozen_string_literal: true

RSpec.describe :next_week do
  link :next_week, from: :ree_datetime

  it {
    result  = next_week(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 30, 13, 15, 10))
  }

  it {
    result = next_week()

    expect(result).to be_a(DateTime)
  }
end