# frozen_string_literal: true

RSpec.describe :all_day do
  link :all_day, from: :ree_datetime

  it {
    result = all_day(DateTime.new(2022, 5, 26, 13, 15, 15))

    expect(result).to eq(DateTime.new(2022, 5, 26, 0, 0, 0)..DateTime.new(2022, 5, 26, 23, 59, 59.999999))
  }

  it {
    result = all_day()

    expect(result).to be_a(Range)
  }
end