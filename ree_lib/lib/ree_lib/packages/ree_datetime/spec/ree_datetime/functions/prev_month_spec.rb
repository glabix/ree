# frozen_string_literal: true

RSpec.describe :prev_month do
  link :prev_month, from: :ree_datetime

  it {
    result  = prev_month(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 4, 23, 13, 15, 10))
  }

  it {
    result = prev_month()

    expect(result).to be_a(DateTime)
  }
end