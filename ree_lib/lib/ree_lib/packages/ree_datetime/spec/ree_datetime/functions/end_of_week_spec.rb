# frozen_string_literal: true

RSpec.describe :end_of_week do
  link :end_of_week, from: :ree_datetime

  it {
    monday = end_of_week(DateTime.new(2022, 5, 25, 13, 50, 15), :monday)
    sunday = end_of_week(DateTime.new(2022, 5, 25, 13, 50, 15), :sunday)

    expect(monday).to eq(DateTime.new(2022, 5, 29, 23, 59, 59.999999))
    expect(sunday).to eq(DateTime.new(2022, 5, 28, 23, 59, 59.999999))
  }

  it {
    result = end_of_week(:monday)

    expect(result).to be_a(DateTime)
  }
end