# frozen_string_literal: true

RSpec.describe :next_occurring do
  link :next_occurring, from: :ree_datetime

  it {
    monday = next_occurring(DateTime.new(2022, 5, 23, 13, 15, 20), :monday)
    wednesday = next_occurring(DateTime.new(2022, 5, 19, 13, 15, 20), :wednesday)
    thursday = next_occurring(DateTime.new(2022, 5, 23, 13, 15, 20), :thursday)
    saturday = next_occurring(DateTime.new(2022, 5, 23, 13, 15, 20), :saturday)
    sunday = next_occurring(DateTime.new(2022, 5, 8, 13, 15, 20), :sunday)


    expect(monday).to eq(DateTime.new(2022, 5, 30, 13, 15, 20))
    expect(wednesday).to eq(DateTime.new(2022, 5, 25, 13, 15, 20))
    expect(thursday).to eq(DateTime.new(2022, 6, 2, 13, 15, 20))
    expect(saturday).to eq(DateTime.new(2022, 6, 4, 13, 15, 20))
    expect(sunday).to eq(DateTime.new(2022, 5, 15, 13, 15, 20))
  }

  it {
    result = next_occurring(:sunday)

    expect(result).to be_a(DateTime)
  }
end