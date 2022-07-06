# frozen_string_literal: true

RSpec.describe :seconds_since do
  link :seconds_since, from: :ree_datetime

  it {
    result = seconds_since(DateTime.new(2020, 4, 3, 4, 15, 30), 20)

    expect(result).to eq(DateTime.new(2020, 4, 3, 4, 15, 50))
  }

  it {
    result = seconds_since(10)

    expect(result).to be_a(DateTime)
  }
end