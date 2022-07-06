# frozen_string_literal: true

RSpec.describe :weeks_since do
  link :weeks_since, from: :ree_datetime

  it {
    result = weeks_since(DateTime.new(2022, 5, 23, 13, 15, 20), 3)

    expect(result).to eq(DateTime.new(2022, 6, 13, 13, 15, 20))
  }

  it {
    result = weeks_since(3)

    expect(result).to be_a(DateTime)
  }
end