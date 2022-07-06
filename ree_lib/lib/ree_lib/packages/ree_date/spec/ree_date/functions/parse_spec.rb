# frozen_string_literal: true

RSpec.describe :parse do
  link :parse, from: :ree_date

  it {
    date_1 = parse('2001-02-03')
    date_2 = parse('20010203')
    date_3 = parse('3rd Feb 2001')

    expect(date_1).to eq(Date.new(2001, 2, 3))
    expect(date_2).to eq(Date.new(2001, 2, 3))
    expect(date_3).to eq(Date.new(2001, 2, 3))
  }

  it {
    result = parse('2001-02-03')

    expect(result).to be_a(Date)
  }
end