# frozen_string_literal: true

RSpec.describe :prev_hour do
  link :prev_hour, from: :ree_datetime

  it {
    result  = prev_hour(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 23, 12, 15, 10))
  }

  it {
    result = prev_hour()

    expect(result).to be_a(DateTime)
  }
end