# frozen_string_literal: true

RSpec.describe :change do
  link :change, from: :ree_datetime

  it {
    hour = change(DateTime.new(2022, 3, 2, 4, 15, 20), hour: 3)
    min = change(DateTime.new(2022, 3, 2, 4, 15, 20), min: 6)
    sec = change(DateTime.new(2022, 3, 2, 4, 15, 20), sec: 37)
    year_hour = change(DateTime.new(2022, 3, 2, 4, 15, 20), year: 2019, hour: 3)
    nsec = change(DateTime.new(2022, 3, 2, 4, 15, 20), nsec: 5)
    usec = change(DateTime.new(2022, 3, 2, 4, 15, 20), usec: 5)
    offset = change(DateTime.new(2022, 3, 2, 4, 15, 20), offset: 3/24r)
    h_m_s_usec = change(DateTime.new(2022, 3, 2, 4, 15, 20), hour: 5, min: 4, sec: 2, usec: 999999)

    expect(hour).to eq(DateTime.new(2022, 3, 2, 3, 15, 20))
    expect(min).to eq(DateTime.new(2022, 3, 2, 4, 6, 20))
    expect(sec).to eq(DateTime.new(2022, 3, 2, 4, 15, 37))
    expect(year_hour).to eq(DateTime.new(2019, 3, 2, 3, 15, 20))
    expect(nsec).to eq(DateTime.new(2022, 3, 2, 4, 15, 20.000000005))
    expect(usec).to eq(DateTime.new(2022, 3, 2, 4, 15, 20.000005))
    expect(offset).to eq(DateTime.new(2022, 3, 2, 4, 15, 20, '+3'))
    expect(h_m_s_usec).to eq(DateTime.new(2022, 3, 2, 5, 4, 2.999999))
  }
end