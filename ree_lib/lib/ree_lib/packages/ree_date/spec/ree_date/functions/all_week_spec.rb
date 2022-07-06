# frozen_string_literal: true

RSpec.describe :all_week do
  link :all_week, from: :ree_date

  it {
    result_monday = all_week(Date.new(2022, 4, 6), :monday)
    result_sunday = all_week(Date.new(2022, 4, 6), :sunday)

    expect(result_monday).to eq(Date.new(2022, 4, 4)..Date.new(2022, 4, 10))
  }

  it {
    result = all_week(:monday)

    expect(result).to be_a(Range)
  }
end