# frozen_string_literal: true

RSpec.describe :find_human_time_zones_by_offset do
  link :find_human_time_zones_by_offset, from: :ree_datetime

  it {
    gmt_12 = find_human_time_zones_by_offset("+12:00")

    expect(gmt_12).to be_a(Array)
  }
end