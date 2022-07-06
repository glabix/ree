# frozen_string_literal: true

RSpec.describe :beginning_of_month do
  link :beginning_of_month, from: :ree_date

  it {
    result = beginning_of_month(Date.new(2020, 4, 12))
    expect(result).to eq(Date.new(2020, 4, 1))
  }

  it {
    result = beginning_of_month()
    expect(result).to eq(Date.new(Date.today.year, Date.today.month, 1))
  }
end