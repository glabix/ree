# frozen_string_literal: true

RSpec.describe :friday do
  link :friday, from: :ree_date

  it {
    result = friday(Date.new(2022, 4, 2))

    expect(result).to eq(Date.new(2022, 4, 1)) 
  }

  it {
    result = friday()

    expect(result).to be_a(Date)
  }
end