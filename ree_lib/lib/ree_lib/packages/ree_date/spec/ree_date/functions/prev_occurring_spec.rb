# frozen_string_literal: true

RSpec.describe :prev_occurring do
  link :prev_occurring, from: :ree_date

  it {
    monday = prev_occurring(Date.new(2022, 5, 23), :monday)
    wednesday = prev_occurring(Date.new(2022, 5, 19), :wednesday)
    thursday = prev_occurring(Date.new(2022, 5, 23), :thursday)
    saturday = prev_occurring(Date.new(2022, 5, 23), :saturday)
    sunday = prev_occurring(Date.new(2022, 5, 8), :sunday)


    expect(monday).to eq(Date.new(2022, 5, 16))
    expect(wednesday).to eq(Date.new(2022, 5, 11))
    expect(thursday).to eq(Date.new(2022, 5, 19))
    expect(saturday).to eq(Date.new(2022, 5, 21))
    expect(sunday).to eq(Date.new(2022, 5, 1))
  }

  it {
    result = prev_occurring(:sunday)

    expect(result).to be_a(Date)
  }
end