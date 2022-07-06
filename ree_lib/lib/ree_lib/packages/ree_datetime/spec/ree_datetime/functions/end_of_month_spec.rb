# frozen_string_literal: true

RSpec.describe :end_of_month do
  link :end_of_month, from: :ree_datetime

  it {
    result = end_of_month(DateTime.new(2022, 5, 26, 13, 15, 0))

    expect(result).to eq(DateTime.new(2022, 5, 31, 23, 59, 59.999999))
  }

  it {
    result = end_of_month()

    expect(result).to be_a(DateTime)
  }
end