# frozen_string_literal: true

RSpec.describe :hours_ago do
  link :hours_ago, from: :ree_datetime

  it {
    result_1 = hours_ago(DateTime.new(2022, 5, 26, 13, 15, 20), 14)
    result_2 = hours_ago(DateTime.new(2022, 5, 26, 13, 15, 20), 5)

    expect(result_1).to eq(DateTime.new(2022, 5, 25, 23, 15, 20))
    expect(result_2).to eq(DateTime.new(2022, 5, 26, 8, 15, 20))
  }

  it {
    result = hours_ago(5)

    expect(result).to be_a(DateTime)
  }
end