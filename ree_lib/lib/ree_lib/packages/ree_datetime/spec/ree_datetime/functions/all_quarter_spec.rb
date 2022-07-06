# frozen_string_literal: true

RSpec.describe :all_quarter do
  link :all_quarter, from: :ree_datetime

  it {
    result = all_quarter(DateTime.new(2022, 5, 3, 13, 15, 40))

    expect(result).to eq(DateTime.new(2022, 4, 1, 0, 0, 0)..DateTime.new(2022, 6, 30, 23, 59, 59.999999))
  }

  it {
    result = all_quarter()

    expect(result).to be_a(Range)
  }
end