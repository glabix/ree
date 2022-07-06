# frozen_string_literal: true

RSpec.describe :prev_year do
  link :prev_year, from: :ree_date

  it {
    result = prev_year(Date.new(2020, 12, 2))
    expect(result).to eq(Date.new(2019, 12, 2))
  }

  it {
    result = prev_year()
    expect(result).to eq(Date.today << 12)
  }
end