# frozen_string_literal: true

RSpec.describe :tuesday do
  link :tuesday, from: :ree_date

  it {
    result = tuesday(Date.new(2022, 4, 2))

    expect(result).to eq(Date.new(2022, 3, 29))
  }

  it {
    result = tuesday()

    expect(result).to be_a(Date)
  }
end