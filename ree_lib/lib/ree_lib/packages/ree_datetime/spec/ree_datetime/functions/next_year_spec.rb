# frozen_string_literal: true

RSpec.describe :next_year do
  link :next_year, from: :ree_datetime

  it {
    result  = next_year(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2023, 5, 23, 13, 15, 10))
  }

  it {
    result = next_year()

    expect(result).to be_a(DateTime)
  }
end