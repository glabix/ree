# frozen_string_literal: true

RSpec.describe :prev_day do
  link :prev_day, from: :ree_date

  it {
    result = prev_day(Date.new(2020, 12, 2))
    expect(result).to eq(Date.new(2020, 12, 1))
  }

  it {
    result = prev_day()
    expect(result).to eq(Date.today - 1)
  }
end