# frozen_string_literal: true

RSpec.describe :today do
  link :today, from: :ree_date

  it {
    result = today()
    expect(result).to be_a(Date)
    expect(result).to eq(Date.today)
  }
end