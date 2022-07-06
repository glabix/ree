# frozen_string_literal: true

RSpec.describe :end_of_minute do
  link :end_of_minute, from: :ree_datetime

  it {
    result = end_of_minute(DateTime.new(2022, 5, 26, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 26, 13, 15, 59.999999))
  }

  it {
    result = end_of_minute()

    expect(result).to be_a(DateTime)
  }
end