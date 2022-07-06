# frozen_string_literal: true

RSpec.describe :days_ago do
  link :days_ago, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    day_count = 5
    result = days_ago(date, day_count)
    expect(result).to eq(Date.new(2020, 11, 10))
  }

  it {
    day_count = 5
    result = days_ago(day_count)
    expect(result).to eq(Date.today - day_count)
  }
end