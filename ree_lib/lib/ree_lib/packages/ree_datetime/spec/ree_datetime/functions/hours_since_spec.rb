# frozen_string_literal: true

RSpec.describe :hours_since do
  link :hours_since, from: :ree_datetime

  it {
    result_1 = hours_since(DateTime.new(2022, 5, 26, 13, 15, 20), 14)
    result_2 = hours_since(DateTime.new(2022, 5, 26, 13, 15, 20), 5)

    expect(result_1).to eq(DateTime.new(2022, 5, 27, 3, 15, 20))
    expect(result_2).to eq(DateTime.new(2022, 5, 26, 18, 15, 20))
  }

  it {
    result = hours_since(5)

    expect(result).to be_a(DateTime)
  }
end