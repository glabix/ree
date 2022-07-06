# frozen_string_literal: true

RSpec.describe :squish do
  link :squish, from: :ree_string

  it {
    multiline = %{ Multi-line
          string }
    
    expect(squish(multiline)).to eq("Multi-line string")
    expect(squish(" foo   bar    \n   \t   boo")).to eq("foo bar boo")
  }
end