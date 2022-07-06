# frozen_string_literal: true

RSpec.describe :seconds_ago do
  link :seconds_ago, from: :ree_datetime

  it {
    result = seconds_ago(DateTime.new(2022, 4, 5, 3, 50, 15), 15)

    expect(result).to eq(DateTime.new(2022, 4, 5, 3, 50, 0))
  }

  it {
    result = seconds_ago(10)

    expect(result).to be_a(DateTime)
  }
end