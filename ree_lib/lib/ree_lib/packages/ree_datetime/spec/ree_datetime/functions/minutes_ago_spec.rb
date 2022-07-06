# frozen_string_literal: true

RSpec.describe :minutes_ago do
  link :minutes_ago, from: :ree_datetime

  it {
    result = minutes_ago(DateTime.new(2022, 5, 12, 13, 15, 10), 20)

    expect(result).to eq(DateTime.new(2022, 5, 12, 12, 55, 10))
  }

  it {
    result = minutes_ago(20)

    expect(result).to be_a(DateTime)
  }
end