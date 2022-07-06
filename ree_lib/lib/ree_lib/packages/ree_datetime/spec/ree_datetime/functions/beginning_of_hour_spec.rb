# frozen_string_literal: true

RSpec.describe :beginning_of_hour do
  link :beginning_of_hour, from: :ree_datetime

  it {
    result = beginning_of_hour(DateTime.new(2022, 5, 26, 13, 15, 10))

    expect(result).to eq(DateTime.new(2022, 5, 26, 13, 0, 0))
  }

  it {
    result = beginning_of_hour()

    expect(result).to be_a(DateTime)
  }
end