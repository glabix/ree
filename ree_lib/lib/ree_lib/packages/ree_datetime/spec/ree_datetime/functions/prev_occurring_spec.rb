# frozen_string_literal: true

RSpec.describe :prev_occurring do
  link :prev_occurring, from: :ree_datetime

  it {
    monday = prev_occurring(DateTime.new(2022, 5, 23, 13, 12, 27), :monday)
    wednesday = prev_occurring(DateTime.new(2022, 5, 19, 13, 12, 27), :wednesday)
    thursday = prev_occurring(DateTime.new(2022, 5, 23, 13, 12, 27), :thursday)
    saturday = prev_occurring(DateTime.new(2022, 5, 23, 13, 12, 27), :saturday)
    sunday = prev_occurring(DateTime.new(2022, 5, 8, 13, 12, 27), :sunday)


    expect(monday).to eq(DateTime.new(2022, 5, 16, 13, 12, 27))
    expect(wednesday).to eq(DateTime.new(2022, 5, 11, 13, 12, 27))
    expect(thursday).to eq(DateTime.new(2022, 5, 19, 13, 12, 27))
    expect(saturday).to eq(DateTime.new(2022, 5, 21, 13, 12, 27))
    expect(sunday).to eq(DateTime.new(2022, 5, 1, 13, 12, 27))
  }

  it {
    result = prev_occurring(:sunday)

    expect(result).to be_a(DateTime)
  }
end