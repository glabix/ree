# frozen_string_literal: true

RSpec.describe :beginning_of_week do
  link :beginning_of_week, from: :ree_datetime

  it {
    monday = beginning_of_week(DateTime.new(2022, 5, 25, 13, 50, 15), :monday)
    sunday = beginning_of_week(DateTime.new(2022, 5, 25, 13, 50, 15), :sunday)

    expect(monday).to eq(DateTime.new(2022, 5, 23, 0, 0, 0))
    expect(sunday).to eq(DateTime.new(2022, 5, 22, 0, 0, 0))
  }

  it {
    result = beginning_of_week(:monday)

    expect(result).to be_a(DateTime)
  }
end