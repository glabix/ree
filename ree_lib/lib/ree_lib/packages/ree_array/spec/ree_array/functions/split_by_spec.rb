# frozen_string_literal: true

RSpec.describe :split_by do
  link :split_by, from: :ree_array

  it "with empty array" do
    expect(split_by([], 0)).to eq([[]])
  end

  it "with argument" do
    expect(split_by([1, 2, 3, 4, 5], 3)).to eq([[1, 2], [4, 5]])
  end

  it "with block" do
    a = (1..10).to_a
    expect(split_by(a) { |i| i % 3 == 0 } ).to eq([[1, 2], [4, 5], [7, 8], [10]])
  end

  it "with edge values" do
    a = [1, 2, 3, 4, 5]
    expect(split_by(a, 1)).to eq([[], [2, 3, 4, 5]])
    expect(split_by(a, 5)).to eq([[1, 2, 3, 4], []])
    expect(split_by(a) { |i| i == 1 || i == 5 } ).to eq([[], [2, 3, 4], []])
  end

  it "with repeated values" do
    a = [1, 2, 3, 5, 5, 3, 4, 6, 2, 1, 3]
    expect(split_by(a, 3)).to eq([[1, 2], [5, 5], [4, 6, 2, 1], []])
    expect(split_by(a, 5)).to eq([[1, 2, 3], [], [3, 4, 6, 2, 1, 3]])
    expect(split_by(a) { |i| i == 3 || i == 5 } ).to eq([[1, 2], [], [], [], [4, 6, 2, 1], []])
  end
end