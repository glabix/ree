# frozen_string_literal: true

RSpec.describe :months_ago do
  link :months_ago, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    month_count = 2
    result = months_ago(date, month_count)
    expect(result).to eq(Date.new(2020, 9, 15))
  }

  it {
    month_count = 5
    result = months_ago(month_count)
    expect(result).to eq(Date.today << month_count)
  }
end