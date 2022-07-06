# frozen_string_literal: true

RSpec.describe :is_week_day do
  link :is_week_day, from: :ree_datetime

  it {
    week_day = is_week_day(DateTime.new(2022, 5, 23, 13, 15, 34))
    weekend_day = is_week_day(DateTime.new(2022, 5, 22, 13, 15, 34))

    expect(week_day).to eq(true)
    expect(weekend_day).to eq(false)
  }

  it {
    result = is_week_day()

    expect(result).to be(true).or be(false)
  }
end