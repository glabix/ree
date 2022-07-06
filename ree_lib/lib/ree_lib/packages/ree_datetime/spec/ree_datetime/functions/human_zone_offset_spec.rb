# frozen_string_literal: true

RSpec.describe :human_zone_offset do
  link :human_zone_offset, from: :ree_datetime
  link :find_tzinfo, from: :ree_datetime
  link :offset_to_string, from: :ree_datetime

  it {
    tzinfo = find_tzinfo("Europe/Moscow")
    expect(human_zone_offset("Moscow")).to eq(offset_to_string(tzinfo.utc_offset))
  }

  it {
    expect {
      human_zone_offset("UNDEFINED")
    }.to raise_error(ArgumentError)
  }
end