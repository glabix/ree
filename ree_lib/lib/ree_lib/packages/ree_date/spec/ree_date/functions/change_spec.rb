# frozen_string_literal: true

RSpec.describe :change do
  link :change, from: :ree_date

  it {
    change_year = change(Date.new(2020, 12, 1), year: 2017)
    change_month = change(Date.new(2020, 12, 1), month: 3)
    change_day = change(Date.new(2020, 12, 1), day: 16)
    change_all = change(Date.new(2020, 12, 1), year: 2012, month: 5, day: 7)

    expect(change_year).to eq(Date.new(2017, 12, 1))
    expect(change_month).to eq(Date.new(2020, 3, 1))
    expect(change_day).to eq(Date.new(2020, 12, 16))
    expect(change_all).to eq(Date.new(2012, 5, 7))
  }
end