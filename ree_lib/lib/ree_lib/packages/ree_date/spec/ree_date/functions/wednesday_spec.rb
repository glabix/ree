# frozen_string_literal: true

RSpec.describe :wednesday do
  link :wednesday, from: :ree_date

  it {
    result = wednesday(Date.new(2022, 4, 2))

    expect(result).to eq(Date.new(2022, 3, 30))
  }

  it {
    result = wednesday()

    expect(result).to be_a(Date)
  }
end