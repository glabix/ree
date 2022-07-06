# frozen_string_literal: true

RSpec.describe :next_year do
  link :next_year, from: :ree_date

  it {
    result = next_year(Date.new(2020, 12, 2))

    expect(result).to eq(Date.new(2021, 12, 2))
  }

  it {
    result = next_year()
    expect(result).to eq(Date.today >> 12)
  }
end