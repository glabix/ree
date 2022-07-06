# frozen_string_literal: true

RSpec.describe :all_week do
  link :all_week, from: :ree_datetime

  it {
    monday = all_week(DateTime.new(2022, 5, 25, 13, 15, 15), :monday)
    sunday = all_week(DateTime.new(2022, 5, 25, 13, 15, 15), :sunday)

    expect(monday).to eq(DateTime.new(2022, 5, 23, 0, 0, 0)..DateTime.new(2022, 5, 29, 23, 59, 59.999999))
    expect(sunday).to eq(DateTime.new(2022, 5, 22, 0, 0, 0)..DateTime.new(2022, 5, 28, 23, 59, 59.999999))
  }

  it {
    result = all_week(:monday)

    expect(result).to be_a(Range)
  }
end