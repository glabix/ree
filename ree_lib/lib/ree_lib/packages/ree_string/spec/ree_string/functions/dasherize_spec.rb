# frozen_string_literal: true

RSpec.describe :dasherize do
  link :dasherize, from: :ree_string

  it {
    expect(dasherize('puni_puni')).to eq("puni-puni")
  }
end