# frozen_string_literal: true

RSpec.describe :in_time_zone do
  link :in_time_zone, from: :ree_datetime

  it {
    vladivostok = in_time_zone(DateTime.new(2022, 4, 5, 11, 4, 15, "+03:00"), "Vladivostok")
    caracas = in_time_zone(DateTime.new(2022, 4, 5, 11, 4, 15, "+03:00"), "Caracas")
    new_day_auckland = in_time_zone(DateTime.new(2022, 4, 5, 23, 4, 15, "+03:00"), "Pacific/Auckland")
    prev_day_bogota = in_time_zone(DateTime.new(2022, 4, 5, 5, 4, 15, "+03:00"), "Bogota")

    expect(vladivostok).to eq(DateTime.new(2022, 4, 5, 18, 4, 15, "+10:00"))
    expect(caracas).to eq(DateTime.new(2022, 4, 5, 4, 4, 15, "-04:00"))
    expect(new_day_auckland).to eq(DateTime.new(2022, 4, 6, 8, 4, 15, "+12:00"))
    expect(prev_day_bogota).to eq(DateTime.new(2022, 4, 4, 21, 4, 15, "-05:00"))
  }
end