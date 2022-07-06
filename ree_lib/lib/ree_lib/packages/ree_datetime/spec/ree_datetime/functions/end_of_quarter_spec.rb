# frozen_string_literal: true

RSpec.describe :end_of_quarter do
  link :end_of_quarter, from: :ree_datetime

  it {
    result = end_of_quarter(DateTime.new(2022, 5, 3, 13, 15, 20))

    expect(result).to eq(DateTime.new(2022, 6, 30, 23, 59, 59.999999))
  }

  it {
    result = end_of_quarter()

    expect(result).to be_a(DateTime)
  }
end