# frozen_string_literal: true

RSpec.describe :days_to_week_start do
  link :days_to_week_start, from: :ree_date

  it {
    result_to_monday = days_to_week_start(Date.new(2022, 5, 26), :monday)
    result_to_sunday = days_to_week_start(Date.new(2022, 5, 26), :sunday)

    expect(result_to_monday).to eq(3)
    expect(result_to_sunday).to eq(4)
  }

  it {
    result = days_to_week_start(:monday)

    expect(result).to be_a(Integer)
  }
end