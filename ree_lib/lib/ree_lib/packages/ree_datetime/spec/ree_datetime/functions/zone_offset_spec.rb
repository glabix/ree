# frozen_string_literal: true

RSpec.describe :zone_offset do
  link :zone_offset, from: :ree_datetime

  it {
    expect(zone_offset("Europe/Moscow")).to be_a(String)
  }
end