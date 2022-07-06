# frozen_string_literal: true

RSpec.describe :months_since do
  link :months_since, from: :ree_datetime

  it {
    result = months_since(DateTime.new(2022, 5, 5, 13, 15, 30), 4)

    expect(result).to eq(DateTime.new(2022, 9, 5, 13, 15, 30))
  }

  it {
    result = months_since(4)

    expect(result).to be_a(DateTime)
  }
end