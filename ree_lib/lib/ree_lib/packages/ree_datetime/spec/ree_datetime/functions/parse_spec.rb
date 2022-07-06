# frozen_string_literal: true

RSpec.describe :parse do
  link :parse, from: :ree_datetime

  it {
    date_time_1 = parse('2001-02-03T04:05:06+07:00')
    date_time_2 = parse('20010203T040506+0700')
    date_time_3 = parse('3rd Feb 2001 04:05:06 PM')

    expect(date_time_1).to eq(DateTime.new(2001,2,3,4,5,6, '+7'))
    expect(date_time_2).to eq(DateTime.new(2001,2,3,4,5,6, '+7'))
    expect(date_time_3).to eq(DateTime.new(2001,2,3,16,5,6))
  }
end