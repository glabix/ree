# frozen_string_literal: true

RSpec.describe :friday do
  link :friday, from: :ree_datetime

  it {
    result = friday(DateTime.new(2022, 5, 3, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 6, 13, 40, 30))
  }

  it {
    result = friday()

    expect(result).to be_a(DateTime)
  }
end