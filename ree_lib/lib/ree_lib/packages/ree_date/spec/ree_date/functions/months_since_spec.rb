# frozen_string_literal: true

RSpec.describe :months_since do
  link :months_since, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    month_count = 2
    result = months_since(date, month_count)
    expect(result).to eq(Date.new(2021, 1, 15))
  }

  it {
    month_count = 5
    result = months_since(month_count)
    expect(result).to eq(Date.today >> month_count)
  }
end