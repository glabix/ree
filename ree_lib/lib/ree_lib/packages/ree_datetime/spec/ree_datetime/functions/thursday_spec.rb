# frozen_string_literal: true

RSpec.describe :thursday do
  link :thursday, from: :ree_datetime

  it {
    result = thursday(DateTime.new(2022, 5, 3, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 5, 13, 40, 30))
  }

  it {
    result = thursday()

    expect(result).to be_a(DateTime)
  }
end