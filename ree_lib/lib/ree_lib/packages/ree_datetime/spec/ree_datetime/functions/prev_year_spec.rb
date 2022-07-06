# frozen_string_literal: true

RSpec.describe :prev_year do
  link :prev_year, from: :ree_datetime

  it {
    result  = prev_year(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2021, 5, 23, 13, 15, 10))
  }

  it {
    result = prev_year()

    expect(result).to be_a(DateTime)
  }
end