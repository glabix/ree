# frozen_string_literal: true

RSpec.describe :all_year do
  link :all_year, from: :ree_date

  it {
    result = all_year(Date.new(2020, 4, 5))

    expect(result).to eq(Date.new(2020, 1, 1)..Date.new(2020, 12, 31))
  }

  it {
    result = all_year()

    expect(result).to be_a(Range)
  }
end