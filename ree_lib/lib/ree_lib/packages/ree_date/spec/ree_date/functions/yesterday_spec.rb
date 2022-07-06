# frozen_string_literal: true

RSpec.describe :yesterday do
  link :yesterday, from: :ree_date

  it {
    date = Date.new(2020,8,31)
    result = yesterday(date)
    expect(result).to be_a(Date)
    expect(result).to eq(Date.new(2020,8,30))
  }

  it {
    result = yesterday()
    expect(result).to be_a(Date)
    expect(result).to eq(Date.today - 1)
  }
end