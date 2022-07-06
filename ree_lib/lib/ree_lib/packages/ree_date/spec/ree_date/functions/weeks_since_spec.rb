# frozen_string_literal: true

RSpec.describe :weeks_since do
  link :weeks_since, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    week_count = 2
    result = weeks_since(date, week_count)
    expect(result).to eq(Date.new(2020, 11, 29))
  }

  it {
    week_count = 5
    result = weeks_since(week_count)
    expect(result).to eq(Date.today + week_count * 7)
  }
end