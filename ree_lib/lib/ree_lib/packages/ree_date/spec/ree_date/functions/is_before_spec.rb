# frozen_string_literal: true

RSpec.describe :is_before do
  link :is_before, from: :ree_date

  it {
    before = is_before(Date.new(2020, 5, 3), Date.new(2020, 5, 7))
    after= is_before(Date.new(2020, 5, 7), Date.new(2020, 5, 3))

    expect(before).to eq(true)
    expect(after).to eq(false)
  }
end