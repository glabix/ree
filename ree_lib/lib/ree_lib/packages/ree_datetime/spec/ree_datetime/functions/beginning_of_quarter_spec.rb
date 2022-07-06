# frozen_string_literal: true

RSpec.describe :beginning_of_quarter do
  link :beginning_of_quarter, from: :ree_datetime

  it {
    result = beginning_of_quarter(DateTime.new(2022, 5, 3, 13, 15, 20))

    expect(result).to eq(DateTime.new(2022, 4, 1, 0, 0, 0))
  }

  it {
    result = beginning_of_quarter()

    expect(result).to be_a(DateTime)
  }
end