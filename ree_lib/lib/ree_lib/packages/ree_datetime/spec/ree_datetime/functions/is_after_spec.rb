# frozen_string_literal: true

RSpec.describe :is_after do
  link :is_after, from: :ree_datetime

  it {
    after = is_after(DateTime.new(2019, 2, 6, 13, 15, 20), DateTime.new(2020, 2, 6, 13, 15, 20))
    before = is_after(DateTime.new(2022, 5, 9, 13, 15, 20), DateTime.new(2022, 3, 9, 13, 15, 20))
    time_after = is_after(DateTime.new(2019, 2, 6, 13, 15, 20), DateTime.new(2019, 2, 6, 13, 20, 20))
    time_before = is_after(DateTime.new(2019, 2, 6, 13, 15, 20), DateTime.new(2019, 2, 6, 10, 15, 20))

    expect(after).to eq(true)
    expect(before).to eq(false)
    expect(time_after).to eq(true)
    expect(time_before).to eq(false)
  }
end