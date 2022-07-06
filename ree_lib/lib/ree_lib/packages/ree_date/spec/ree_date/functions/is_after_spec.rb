# frozen_string_literal: true

RSpec.describe :is_after do
  link :is_after, from: :ree_date

  it {
    after = is_after(Date.new(2019, 2, 6), Date.new(2020, 2, 6))
    before = is_after(Date.new(2022, 5, 9), Date.new(2022, 3, 9))

    expect(after).to eq(true)
    expect(before).to eq(false)
  }
end