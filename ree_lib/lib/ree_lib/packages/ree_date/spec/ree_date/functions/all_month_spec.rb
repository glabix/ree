# frozen_string_literal: true

RSpec.describe :all_month do
  link :all_month, from: :ree_date

  it {
    result = all_month(Date.new(2020, 1, 4))

    expect(result).to eq(Date.new(2020, 1, 1)..Date.new(2020, 1, 31))
  }

  it {
    result = all_month()

    expect(result).to be_a(Range)
  }
end