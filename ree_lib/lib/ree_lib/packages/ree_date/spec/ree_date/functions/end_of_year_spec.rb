# frozen_string_literal: true

RSpec.describe :end_of_year do
  link :end_of_year, from: :ree_date

  it {
    result = end_of_year(Date.new(2020, 2, 6))

    expect(result).to eq(Date.new(2020, 12, 31))
  }

  it {
    result = end_of_year()

    expect(result).to eq(Date.new(Date.today.year, 12, 31))
  }
end