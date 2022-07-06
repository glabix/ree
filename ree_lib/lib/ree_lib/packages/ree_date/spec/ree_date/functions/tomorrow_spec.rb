# frozen_string_literal: true

RSpec.describe :tomorrow do
  link :tomorrow, from: :ree_date

  it {
    date = Date.new(2020,8,31)
    result = tomorrow(date)
    expect(result).to be_a(Date)
    expect(result).to eq(Date.new(2020,9,1))
  }

  it {
    result = tomorrow()
    expect(result).to be_a(Date)
    expect(result).to eq(Date.today + 1)
  }
end