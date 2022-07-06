# frozen_string_literal: true

RSpec.describe :saturday do
  link :saturday, from: :ree_datetime

  it {
    result = saturday(DateTime.new(2022, 5, 3, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 7, 13, 40, 30))
  }

  it {
    result = saturday()

    expect(result).to be_a(DateTime)
  }
end