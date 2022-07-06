# frozen_string_literal: true

RSpec.describe :days_ago do
  link :days_ago, from: :ree_datetime

  it {
    result = days_ago(DateTime.new(2022, 5, 25, 13, 15, 20), 5)

    expect(result).to eq(DateTime.new(2022, 5, 20, 13, 15, 20))
  }

  it {
    result = days_ago(5)

    expect(result).to be_a(DateTime)
  }
end