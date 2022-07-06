# frozen_string_literal: true

RSpec.describe :beginning_of_day do
  link :beginning_of_day, from: :ree_datetime

  it {
    result = beginning_of_day(DateTime.new(2022, 5, 26, 13, 15, 15))
    
    expect(result).to eq(DateTime.new(2022, 5, 26, 0, 0, 0))
  }

  it {
    result = beginning_of_day()

    expect(result).to be_a(DateTime)
  }
end