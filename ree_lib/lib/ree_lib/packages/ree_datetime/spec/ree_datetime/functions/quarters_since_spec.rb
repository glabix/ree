# frozen_string_literal: true

RSpec.describe :quarters_since do
  link :quarters_since, from: :ree_datetime

  it {
    result = quarters_since(DateTime.new(2022, 5, 3, 13, 20, 30), 2)

    expect(result).to eq(DateTime.new(2022, 11, 3, 13, 20, 30))
  }

  it {
    result = quarters_since(2)

    expect(result).to be_a(DateTime)
  }
end