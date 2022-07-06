# frozen_string_literal: true

RSpec.describe :thursday do
  link :thursday, from: :ree_date

  it {
    result = thursday(Date.new(2022, 4, 2))

    expect(result).to eq(Date.new(2022, 3, 31))
  }

  it {
    result = thursday()

    expect(result).to be_a(Date)
  }
end