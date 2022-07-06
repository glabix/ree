# frozen_string_literal: true

RSpec.describe :next_occurring do
  link :next_occurring, from: :ree_date

  it {
    monday = next_occurring(Date.new(2022, 5, 23), :monday)
    wednesday = next_occurring(Date.new(2022, 5, 19), :wednesday)
    thursday = next_occurring(Date.new(2022, 5, 23), :thursday)
    saturday = next_occurring(Date.new(2022, 5, 23), :saturday)
    sunday = next_occurring(Date.new(2022, 5, 8), :sunday)


    expect(monday).to eq(Date.new(2022, 5, 30))
    expect(wednesday).to eq(Date.new(2022, 5, 25))
    expect(thursday).to eq(Date.new(2022, 6, 2))
    expect(saturday).to eq(Date.new(2022, 6, 4))
    expect(sunday).to eq(Date.new(2022, 5, 15))
  }

  it {
    result = next_occurring(:sunday)

    expect(result).to be_a(Date)
  }
end