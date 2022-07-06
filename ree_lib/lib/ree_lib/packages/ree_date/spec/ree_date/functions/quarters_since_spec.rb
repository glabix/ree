# frozen_string_literal: true

RSpec.describe :quarters_since do
  link :quarters_since, from: :ree_date

  it {
    date = Date.new(2020, 11, 15)
    quarter_count = 2
    result = quarters_since(date, quarter_count)
    expect(result).to eq(Date.new(2021, 5, 15))
  }

  it {
    quarter_count = 5
    result = quarters_since(quarter_count)
    expect(result).to eq(Date.today >> quarter_count * 3)
  }
end