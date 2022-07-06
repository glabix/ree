# frozen_string_literal: true

RSpec.describe :next_hour do
  link :next_hour, from: :ree_datetime

  it {
    result  = next_hour(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 23, 14, 15, 10))
  }

  it {
    result = next_hour()

    expect(result).to be_a(DateTime)
  }
end