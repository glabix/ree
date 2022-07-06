# frozen_string_literal: true

RSpec.describe :years_since do
  link :years_since, from: :ree_datetime

  it {
    result = years_since(DateTime.new(2022, 3, 4, 13, 20, 40), 5)

    expect(result).to eq(DateTime.new(2027, 3, 4, 13, 20, 40))
  }

  it {
    result = years_since(5)

    expect(result).to be_a(DateTime)
  }
end