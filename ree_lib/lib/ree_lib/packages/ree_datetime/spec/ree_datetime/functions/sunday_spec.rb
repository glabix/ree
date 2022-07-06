# frozen_string_literal: true

RSpec.describe :sunday do
  link :sunday, from: :ree_datetime

  it {
    result = sunday(DateTime.new(2022, 5, 5, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 8, 13, 40, 30))
  }

  it {
    result = sunday()

    expect(result).to be_a(DateTime)
  }
end