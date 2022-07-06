# frozen_string_literal: true

RSpec.describe :in_groups do
  link :in_groups, from: :ree_array

  it "returns array size" do
    array = (1..7).to_a
    
    1.upto(array.size + 1) do |number|
      expect(number).to eq(in_groups(array, number).size)
    end
  end

  it "empty array" do
    expect([[], [], []]).to eq(in_groups([], 3))
  end

  it "with block" do
    array = (1..9).to_a
    groups = []

    in_groups(array, 3) do |group|
      groups << group
    end

    expect(in_groups(array, 3)).to eq(groups)
  end

  it "with perfect fit" do
    expect([[1, 2, 3], [4, 5, 6], [7, 8, 9]]).to eq(in_groups((1..9).to_a, 3))
  end

  it "with padding" do
    array = (1..7).to_a

    expect([[1, 2, 3], [4, 5, nil], [6, 7, nil]]).to eq(in_groups(array, 3, fill_with: nil))
    expect([[1, 2, 3], [4, 5, "foo"], [6, 7, "foo"]]).to eq(in_groups(array, 3, fill_with: "foo"))
  end

  it "without padding" do
    expect([[1, 2, 3], [4, 5], [6, 7]]).to eq(in_groups((1..7).to_a, 3))
  end
end