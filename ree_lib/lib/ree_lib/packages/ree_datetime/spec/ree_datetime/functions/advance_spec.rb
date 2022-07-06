# frozen_string_literal: true

RSpec.describe :advance do
  link :advance, from: :ree_datetime

  it {
    years = advance(DateTime.new(2022, 5, 26, 4, 15, 20), years: 4)
    months = advance(DateTime.new(2022, 5, 26, 4, 15, 20), months: 2)
    quarters = advance(DateTime.new(2022, 5, 26, 4, 15, 20), quarters: 1)
    weeks = advance(DateTime.new(2022, 5, 26, 4, 15, 20), weeks: 3)
    days = advance(DateTime.new(2022, 5, 26, 4, 15, 20), days: 5)
    years_months = advance(DateTime.new(2022, 5, 26, 4, 15, 20), years: 4, months: 2)
    years_months_weeks = advance(DateTime.new(2022, 5, 26, 4, 15, 20), years: 4, months: 2, weeks: 3)
    years_months_weeks_days = advance(DateTime.new(2022, 5, 26, 4, 15, 20), years: 1, months: 2, weeks: 1, days: 3)
    hours = advance(DateTime.new(2022, 5, 26, 4, 15, 20), hours: 4)
    over_hours = advance(DateTime.new(2022, 5, 26, 23, 15, 20), hours: 4)
    minutes = advance(DateTime.new(2022, 5, 26, 4, 15, 20), minutes: 20)
    seconds = advance(DateTime.new(2022, 5, 26, 4, 15, 20), seconds: 50)
    years_seconds = advance(DateTime.new(2022, 5, 26, 4, 15, 20), years: 4, seconds: 10)
    minus_h_m_s = advance(DateTime.new(2005, 2, 28, 15, 15, 10), hours: -5, minutes: -7, seconds: -9)
    all = advance(DateTime.new(2005, 2, 28, 15, 15, 10), years: 7, months: 19, quarters: 1, weeks: 2, days: 5, hours: 5, minutes: 7, seconds: 9)


    expect(years).to eq(DateTime.new(2026, 5, 26, 4, 15, 20))
    expect(months).to eq(DateTime.new(2022, 7, 26, 4, 15, 20))
    expect(quarters).to eq(DateTime.new(2022, 8, 26, 4, 15, 20))
    expect(weeks).to eq(DateTime.new(2022, 6, 16, 4, 15, 20))
    expect(days).to eq(DateTime.new(2022, 5, 31, 4, 15, 20))
    expect(years_months).to eq(DateTime.new(2026, 7, 26, 4, 15, 20))
    expect(years_months_weeks).to eq(DateTime.new(2026, 8, 16, 4, 15, 20))
    expect(years_months_weeks_days).to eq(DateTime.new(2023, 8, 5, 4, 15, 20))
    expect(hours).to eq(DateTime.new(2022, 5, 26, 8, 15, 20))
    expect(over_hours).to eq(DateTime.new(2022, 5, 27, 3, 15, 20))
    expect(minutes).to eq(DateTime.new(2022, 5, 26, 4, 35, 20))
    expect(seconds).to eq(DateTime.new(2022, 5, 26, 4, 16, 10))
    expect(years_seconds).to eq(DateTime.new(2026, 5, 26, 4, 15, 30)) 
    expect(minus_h_m_s).to eq(DateTime.new(2005, 2, 28, 10, 8, 1))
    expect(all).to eq(DateTime.new(2014, 1, 16, 20, 22, 19))
  }
end