# frozen_string_literal: true

RSpec.describe :yesterday do
  link :yesterday, from: :ree_datetime

  it {
    result  = yesterday(DateTime.new(2022, 5, 23, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 22, 13, 15, 10))
  }

  it {
    result = yesterday()

    expect(result).to be_a(DateTime)
  }
end