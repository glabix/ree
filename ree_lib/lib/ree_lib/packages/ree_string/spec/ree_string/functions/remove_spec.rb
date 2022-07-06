# frozen_string_literal: true

RSpec.describe :remove do
  link :remove, from: :ree_string

  it {
    expect(remove("foo bar test", [" test", /bar/])).to eq("foo ")
    expect(remove("This is a good day to die", [" to die"])).to eq("This is a good day")
    expect(remove("This is a good day to die", [" to ", /die/])).to eq("This is a good day")
    expect(remove("This is a good day to die to die", [" to die"])).to eq("This is a good day")
  }
end