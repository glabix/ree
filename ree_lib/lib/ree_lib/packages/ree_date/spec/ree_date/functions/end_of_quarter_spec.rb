# frozen_string_literal: true

RSpec.describe :end_of_quarter do
  link :end_of_quarter, from: :ree_date

  it {
    result = end_of_quarter(Date.new(2015, 7, 10))

    expect(result).to eq(Date.new(2015, 9, 30))
  }

  it {
    result = end_of_quarter()

    expect(result).to be_a(Date)
  }
end