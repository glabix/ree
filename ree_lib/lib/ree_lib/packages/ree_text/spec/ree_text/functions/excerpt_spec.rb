# frozen_string_literal: true

RSpec.describe :excerpt do
  link :excerpt, from: :ree_text

  it {
    expect(excerpt("This is an example", "an", radius: 5)).to eq("...s is an exam...")
    expect(excerpt('This is an example', 'is', radius: 5)).to eq("This is a...")
    expect(excerpt('This is an example', 'is')).to eq("This is an example")
    expect(excerpt('This next thing is an example', 'ex', radius: 2)).to eq("...next...")
    expect(excerpt('This is also an example', 'an', radius: 8, omission: '<chop> ')).to eq("<chop> is also an example")
    expect(excerpt('This is a very beautiful morning', 'very', separator: ' ', radius: 1)).to eq("...a very beautiful...")
  }
end