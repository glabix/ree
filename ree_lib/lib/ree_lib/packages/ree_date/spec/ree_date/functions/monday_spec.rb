# frozen_string_literal: true

RSpec.describe :monday do
  link :monday, from: :ree_date

  it {
    result = monday(Date.new(2022, 5, 24))

    expect(result).to eq(Date.new(2022, 5, 23))
  }

  it {
    result = monday()

    expect(result).to be_a(Date)
  }
end