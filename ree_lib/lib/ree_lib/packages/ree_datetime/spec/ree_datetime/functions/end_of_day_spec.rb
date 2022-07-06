# frozen_string_literal: true

RSpec.describe :end_of_day do
  link :end_of_day, from: :ree_datetime

  it {
    result = end_of_day(DateTime.new(2022, 2, 12, 13, 10, 18))

    expect(result).to eq(DateTime.new(2022, 2, 12, 23, 59, 59.999999))
  }

  it {
    result = end_of_day()

    expect(result).to be_a(DateTime)
  }
end