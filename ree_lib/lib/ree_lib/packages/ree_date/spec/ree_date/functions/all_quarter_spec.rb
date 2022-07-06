# frozen_string_literal: true

RSpec.describe :all_quarter do
  link :all_quarter, from: :ree_date

  it {
    result = all_quarter(Date.new(2020, 3, 4))

    expect(result).to eq(Date.new(2020, 1, 1)..Date.new(2020, 3, 31))
  }

  it {
    result = all_quarter()

    expect(result).to be_a(Range)
  }
end