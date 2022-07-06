# frozen_string_literal: true

RSpec.describe :minutes_since do
  link :minutes_since, from: :ree_datetime

  it {
    result_1 = minutes_since(DateTime.new(2022, 5, 26, 13, 7, 20), 60)
    result_2 = minutes_since(DateTime.new(2022, 5, 26, 13, 7, 20), 10)

    expect(result_1).to eq(DateTime.new(2022, 5, 26, 14, 7, 20))
    expect(result_2).to eq(DateTime.new(2022, 5, 26, 13, 17, 20))
  }

  it {
    result = minutes_since(20)

    expect(result).to be_a(DateTime)
  }
end