# frozen_string_literal: true

RSpec.describe :wrap do
  link :wrap, from: :ree_array

  it {
    expect(wrap(nil)).to eq([])
    expect(wrap([1, 2, 3])).to eq([1, 2, 3])
    expect(wrap(0)).to eq([0])
    expect(wrap({ foo: :bar })).to eq([{ foo: :bar }])
  }
end