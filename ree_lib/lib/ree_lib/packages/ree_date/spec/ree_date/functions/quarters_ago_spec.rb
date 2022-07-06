# frozen_string_literal: true

RSpec.describe :quarters_ago do
  link :quarters_ago, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    quarter_count = 2
    result = quarters_ago(date, quarter_count)
    expect(result).to eq(Date.new(2020, 5, 15))
  }

  it {
    quarter_count = 5
    result = quarters_ago(quarter_count)
    expect(result).to eq(Date.today << quarter_count * 3)
  }
end