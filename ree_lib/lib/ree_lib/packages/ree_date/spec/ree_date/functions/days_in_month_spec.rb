# frozen_string_literal: true

RSpec.describe :days_in_month do
  link :days_in_month, from: :ree_date

  it {
    september = days_in_month(9, 2020)
    august = days_in_month(8, 2019)
    leap_february = days_in_month(2, 2008)
    regular_february = days_in_month(2, 2009)

    expect(september).to eq(30)
    expect(august).to eq(31)
    expect(leap_february).to eq(29)
    expect(regular_february).to eq(28)
  }

  it {
    september = days_in_month(9)

    expect(september).to eq(30)
  }
end