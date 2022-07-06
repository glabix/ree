# frozen_string_literal: true

RSpec.describe :prev_week do
  link :prev_week, from: :ree_datetime

  it {
    result  = prev_week(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 16, 13, 15, 10))
  }

  it {
    result = prev_week()

    expect(result).to be_a(DateTime)
  }
end