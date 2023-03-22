# frozen_string_literal: true

RSpec.describe :in_default_time_zone do
  link :in_default_time_zone, from: :ree_datetime
  link :set_default_time_zone, from: :ree_datetime

  it {
    set_default_time_zone('Moscow')

    expect(
      in_default_time_zone(
        DateTime.new(2022, 4, 5, 18, 4, 15, "+00:00")
      )
    ).to eq(
      DateTime.new(2022, 4, 5, 21, 4, 15, "+03:00")
    )
  }
end