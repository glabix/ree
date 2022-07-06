# frozen_string_literal: true

RSpec.describe :tuesday do
  link :tuesday, from: :ree_datetime

  it {
    result = tuesday(DateTime.new(2022, 5, 5, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 3, 13, 40, 30))
  }

  it {
    result = tuesday()

    expect(result).to be_a(DateTime)
  }
end