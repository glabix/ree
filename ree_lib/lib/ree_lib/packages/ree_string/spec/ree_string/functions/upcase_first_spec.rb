# frozen_string_literal: true

RSpec.describe :upcase_first do
  link :upcase_first, from: :ree_string

  it {
    expect(upcase_first('what a Lovely Day')).to eq("What a Lovely Day")
    expect(upcase_first('w')).to eq("W")
    expect(upcase_first('')).to eq("")
  }
end