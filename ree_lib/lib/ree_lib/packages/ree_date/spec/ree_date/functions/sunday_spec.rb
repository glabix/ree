# frozen_string_literal: true

RSpec.describe :sunday do
  link :sunday, from: :ree_date

  it {
    result = sunday(Date.new(2022, 4, 2))

    expect(result).to eq(Date.new(2022, 4, 3))
  }

  it {
    result = sunday()

    expect(result).to be_a(Date)
  }
end