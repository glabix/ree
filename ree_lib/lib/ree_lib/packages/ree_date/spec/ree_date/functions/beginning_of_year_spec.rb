# frozen_string_literal: true

RSpec.describe :beginning_of_year do
  link :beginning_of_year, from: :ree_date

  it {
    result = beginning_of_year(Date.new(2022, 10, 5))

    expect(result).to eq(Date.new(2022, 1, 1))
  }

  it {
    result = beginning_of_year()

    expect(result).to eq(Date.new(Date.today.year, 1, 1))
  }
end