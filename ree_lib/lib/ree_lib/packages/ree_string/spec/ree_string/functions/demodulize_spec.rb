# frozen_string_literal: true

RSpec.describe :demodulize do
  link :demodulize, from: :ree_string

  it {
    expect(
      demodulize('ActiveSupport::Inflector::Inflections')
    ).to eq("Inflections")
    
    expect(demodulize('Inflections')).to eq("Inflections")
    expect(demodulize('::Inflections')).to eq("Inflections")
    expect(demodulize('')).to eq("")
  }
end