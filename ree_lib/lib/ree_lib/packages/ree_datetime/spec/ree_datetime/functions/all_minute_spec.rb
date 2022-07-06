# frozen_string_literal: true

RSpec.describe :all_minute do
  link :all_minute, from: :ree_datetime

  it {
    result = all_minute(DateTime.new(2022, 5, 26,  13, 15, 50))

    expect(result).to eq(DateTime.new(2022, 5, 26,  13, 15, 0)..DateTime.new(2022, 5, 26,  13, 15, 59.999999))
  }

  it {
    result = all_minute()

    expect(result).to be_a(Range)
  }
end