# frozen_string_literal: true

RSpec.describe :beginning_of_quarter do
  link :beginning_of_quarter, from: :ree_date

  it {
    result = beginning_of_quarter(Date.new(2020, 6, 25))

    expect(result).to eq(Date.new(2020, 4, 1))
  }

  it {
    result = beginning_of_quarter()

    expect(result).to be_a(Date)
  }
  
end