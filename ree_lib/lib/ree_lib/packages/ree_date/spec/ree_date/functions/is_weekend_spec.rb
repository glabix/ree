# frozen_string_literal: true

RSpec.describe :is_weekend do
  link :is_weekend, from: :ree_date

  it {
    week_day = is_weekend(Date.new(2022, 5, 23))
    weekend_day = is_weekend(Date.new(2022, 5, 22))

    expect(week_day).to eq(false)
    expect(weekend_day).to eq(true)
  }

  it {
    result = is_weekend()

    expect(result).to be(true).or be(false)
  }
end