# frozen_string_literal: true

RSpec.describe :wednesday do
  link :wednesday, from: :ree_datetime

  it {
    result = wednesday(DateTime.new(2022, 5, 5, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 4, 13, 40, 30))
  }

  it {
    result = wednesday()

    expect(result).to be_a(DateTime)
  }
end