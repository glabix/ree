# frozen_string_literal: true

RSpec.describe :all_hour do
  link :all_hour, from: :ree_datetime

  it {
    result = all_hour(DateTime.new(2022, 5, 26,  13, 15, 50))

    expect(result).to eq(DateTime.new(2022, 5, 26,  13, 0, 0)..DateTime.new(2022, 5, 26,  13, 59, 59.999999))
  }

  it {
    result = all_hour()

    expect(result).to be_a(Range)
  }
end