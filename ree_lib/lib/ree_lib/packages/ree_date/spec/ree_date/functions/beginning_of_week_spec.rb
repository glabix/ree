# frozen_string_literal: true

RSpec.describe :beginning_of_week do
  link :beginning_of_week, from: :ree_date

  it {
    result_sunday = beginning_of_week(Date.new(2022, 5, 24), :sunday)
    result_monday = beginning_of_week(Date.new(2022, 5, 24), :monday)

    expect(result_sunday).to eq(Date.new(2022, 5, 22))
    expect(result_monday).to eq(Date.new(2022, 5, 23))
  }

  it {
    result = beginning_of_week(:monday)

    expect(result).to be_a(Date)
  }
end