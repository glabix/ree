# frozen_string_literal: true

RSpec.describe :end_of_year do
  link :end_of_year, from: :ree_datetime

  it {
    result = end_of_year(DateTime.new(2022, 5, 26, 13, 15, 20))

    expect(result).to eq(DateTime.new(2022, 12, 31, 23, 59, 59.999999))
  }

  it {
    result = end_of_year()

    expect(result).to be_a(DateTime)
  }
end