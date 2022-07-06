# frozen_string_literal: true

RSpec.describe :end_of_month do
  link :end_of_month, from: :ree_date

  it {
    may = end_of_month(Date.new(2022, 5, 23))
    leap_february = end_of_month(Date.new(2008, 2, 3))
    regular_february = end_of_month(Date.new(2022, 2, 3))

    expect(may).to eq(Date.new(2022, 5, 31))
    expect(leap_february).to eq(Date.new(2008, 2, 29))
    expect(regular_february).to eq(Date.new(2022, 2, 28))
  }

  it {
    result = end_of_month()

    expect(result).to be_a(Date)
  }
end