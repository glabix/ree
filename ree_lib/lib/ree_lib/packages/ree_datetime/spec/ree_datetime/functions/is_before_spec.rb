# frozen_string_literal: true

RSpec.describe :is_before do
  link :is_before, from: :ree_datetime

  it {
    before = is_before(DateTime.new(2020, 5, 3, 13, 12, 10), DateTime.new(2020, 5, 7, 13, 12, 10))
    after = is_before(DateTime.new(2020, 5, 7, 13, 12, 10), DateTime.new(2020, 5, 3, 13, 12, 10))
    time_before = is_before(DateTime.new(2020, 5, 3, 13, 12, 10), DateTime.new(2020, 5, 3, 17, 12, 10))
    time_after = is_before(DateTime.new(2020, 5, 3, 13, 12, 10), DateTime.new(2020, 5, 3, 10, 12, 10))

    expect(before).to eq(true)
    expect(after).to eq(false)
    expect(time_before).to eq(true)
    expect(time_after).to eq(false)
  }
end