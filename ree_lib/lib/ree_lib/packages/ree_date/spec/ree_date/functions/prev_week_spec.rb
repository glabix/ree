# frozen_string_literal: true

RSpec.describe :prev_week do
  link :prev_week, from: :ree_date

  it {
    result = prev_week(Date.new(2020, 12, 2))
    expect(result).to eq(Date.new(2020, 11, 25))
  }

  it {
    result = prev_week()
    expect(result).to eq(Date.today - 7)
  }
end