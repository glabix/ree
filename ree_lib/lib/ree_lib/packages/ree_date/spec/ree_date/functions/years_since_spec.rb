# frozen_string_literal: true

RSpec.describe :years_since do
  link :years_since, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    year_count = 2
    result = years_since(date, year_count)
    expect(result).to eq(Date.new(2022, 11, 15))
  }

  it {
    year_count = 5
    result = years_since(year_count)
    expect(result).to eq(Date.today >> year_count * 12)
  }
end