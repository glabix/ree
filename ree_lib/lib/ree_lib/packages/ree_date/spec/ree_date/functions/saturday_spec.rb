# frozen_string_literal: true

RSpec.describe :saturday do
  link :saturday, from: :ree_date

  # Returns Saturday of this week assuming that week starts on Monday.
  it {
    result = saturday(Date.new(2022, 4, 1))

    expect(result).to eq(Date.new(2022, 4, 2))
  }

  it {
    result = saturday()

    expect(result).to be_a(Date)
  }
end