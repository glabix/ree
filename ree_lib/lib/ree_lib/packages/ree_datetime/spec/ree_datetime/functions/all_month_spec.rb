# frozen_string_literal: true

RSpec.describe :all_month do
  link :all_month, from: :ree_datetime

  it {
   result = all_month(DateTime.new(2022, 5, 12, 13, 15, 10))

   expect(result).to eq(DateTime.new(2022, 5, 1, 0, 0, 0)..DateTime.new(2022, 5, 31, 23, 59, 59.999999))
  }

  it {
    result = all_month()

    expect(result).to be_a(Range)
  }
end