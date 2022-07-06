# frozen_string_literal: true

RSpec.describe :years_ago do
  link :years_ago, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    year_count = 2
    result = years_ago(date, year_count)
    expect(result).to eq(Date.new(2018, 11, 15))
  }

  it {
    year_count = 5
    result = years_ago(year_count)
    expect(result).to eq(Date.today << year_count * 12)
  }
end