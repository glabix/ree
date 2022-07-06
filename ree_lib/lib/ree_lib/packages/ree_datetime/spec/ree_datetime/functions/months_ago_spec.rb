# frozen_string_literal: true

RSpec.describe :months_ago do
  link :months_ago, from: :ree_datetime

  it {
    result = months_ago(DateTime.new(2022, 5, 5, 13, 15, 30), 4)

    expect(result).to eq(DateTime.new(2022, 1, 5, 13, 15, 30))
  }

  it {
    result = months_ago(4)

    expect(result).to be_a(DateTime)
  }
end