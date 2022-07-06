# frozen_string_literal: true

RSpec.describe :tomorrow do
  link :tomorrow, from: :ree_datetime

  it {
    result  = tomorrow(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 24, 13, 15, 10))
  }

  it {
    result = tomorrow()

    expect(result).to be_a(DateTime)
  }
end