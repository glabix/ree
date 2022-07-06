# frozen_string_literal: true

RSpec.describe :beginning_of_month do
  link :beginning_of_month, from: :ree_datetime

  it {
    result = beginning_of_month(DateTime.new(2022, 5, 26, 13, 15, 20))

    expect(result).to eq(DateTime.new(2022, 5, 1, 0, 0, 0))
  }

  it {
    result = beginning_of_month()

    expect(result).to be_a(DateTime)
  }
end