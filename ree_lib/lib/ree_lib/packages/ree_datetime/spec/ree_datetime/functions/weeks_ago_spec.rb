# frozen_string_literal: true

RSpec.describe :weeks_ago do
  link :weeks_ago, from: :ree_datetime

  it {
    result = weeks_ago(DateTime.new(2022, 5, 23, 13, 15, 20), 3)

    expect(result).to eq(DateTime.new(2022, 5, 2, 13, 15, 20))
  }

  it {
    result = weeks_ago(3)

    expect(result).to be_a(DateTime)
  }
end