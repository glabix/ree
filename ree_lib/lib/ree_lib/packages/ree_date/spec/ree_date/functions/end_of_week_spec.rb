# frozen_string_literal: true

RSpec.describe :end_of_week do
  link :end_of_week, from: :ree_date

  it {
    result_sunday = end_of_week(Date.new(2022, 5, 23), :sunday)
    result_monday = end_of_week(Date.new(2022, 5,23), :monday)

    expect(result_sunday).to eq(Date.new(2022, 5, 28))
    expect(result_monday).to eq(Date.new(2022, 5, 29))
  }

  it {
    result = end_of_week(:sunday)

    expect(result).to be_a(Date)
  }
end