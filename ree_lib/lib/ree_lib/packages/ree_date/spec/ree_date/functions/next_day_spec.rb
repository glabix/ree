# frozen_string_literal: true

RSpec.describe :next_day do
  link :next_day, from: :ree_date

  it {
    result = next_day(Date.new(2020, 12, 2))
    leap_year_day = next_day(Date.new(2020, 2, 28))

    expect(result).to eq(Date.new(2020, 12, 3))
    expect(leap_year_day).to eq(Date.new(2020, 2, 29))
  }

  it {
    result = next_day()
    expect(result).to eq(Date.today + 1)
  }
end