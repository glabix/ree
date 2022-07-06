# frozen_string_literal: true

RSpec.describe :next_week do
  link :next_week, from: :ree_date

  it {
    result = next_week(Date.new(2020, 12, 2))

    expect(result).to eq(Date.new(2020, 12, 9))
  }

  it {
    result = next_week()
    expect(result).to eq(Date.today + 7)
  }
end