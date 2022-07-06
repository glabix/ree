# frozen_string_literal: true

RSpec.describe :days_since do
  link :days_since, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    day_count = 5
    result = days_since(date, day_count)
    expect(result).to eq(Date.new(2020, 11, 20))
  }

  it {
    day_count = 5
    result = days_since(day_count)
    expect(result).to eq(Date.today + 5)
  }
end