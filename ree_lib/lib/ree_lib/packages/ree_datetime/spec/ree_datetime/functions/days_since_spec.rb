# frozen_string_literal: true

RSpec.describe :days_since do
  link :days_since, from: :ree_datetime

  it {
    result = days_since(DateTime.new(2022, 5, 25, 13, 15, 20), 5)

    expect(result).to eq(DateTime.new(2022, 5, 30, 13, 15, 20))
  }

  it {
    result = days_since(5)

    expect(result).to be_a(DateTime)
  }
end