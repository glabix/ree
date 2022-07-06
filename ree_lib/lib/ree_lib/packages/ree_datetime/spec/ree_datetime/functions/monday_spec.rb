# frozen_string_literal: true

RSpec.describe :monday do
  link :monday, from: :ree_datetime

  it {
    result = monday(DateTime.new(2022, 5, 5, 13, 40, 30))

    expect(result).to eq(DateTime.new(2022, 5, 2, 13, 40, 30))
  }

  it {
    result = monday()

    expect(result).to be_a(DateTime)
  }
end