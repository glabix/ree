# frozen_string_literal: true

RSpec.describe :distance_of_time_in_words do

  INTERVALS = [:years, :months, :weeks, :days, :hours, :minutes, :seconds]
  SECONDS_IN_INTERVAL = INTERVALS.zip(
    [365 * 24 * 60 * 60,
     30 * 24 * 60 * 60,
     7 * 24 * 60 * 60,
     24 * 60 * 60,
     60 * 60,
     60,
     1]).to_h
  link :distance_of_time_in_words, from: :ree_datetime

  let(:err_result) {distance_of_time_in_words(Time.new(2040, 1, 1,2, 15),
                               Time.new(2012, 1, 1, 2, 30))}
  it {
    from_time = Time.now
    expect{ err_result }.to raise_error(ArgumentError)

    expect(distance_of_time_in_words(from_time, from_time + 50 * SECONDS_IN_INTERVAL[:minutes])).to eq('about 1 hour')
    expect(distance_of_time_in_words(from_time, from_time + 15)).to eq('less than a minute')
    expect(distance_of_time_in_words(from_time, from_time + 15, include_seconds: true)).to eq('less than 20 seconds')
    expect(distance_of_time_in_words(from_time, from_time + 60 * SECONDS_IN_INTERVAL[:hours])).to eq('3 days')
    expect(distance_of_time_in_words(from_time, from_time + 45, include_seconds: true)).to eq('less than a minute')
    expect(distance_of_time_in_words(from_time, from_time + 76)).to eq('1 minute')
    expect(distance_of_time_in_words(from_time, from_time + 1 * SECONDS_IN_INTERVAL[:years] + 3 * SECONDS_IN_INTERVAL[:days])).to eq('about 1 year')
    expect(distance_of_time_in_words(from_time, from_time + 3 * SECONDS_IN_INTERVAL[:years] + 6 * SECONDS_IN_INTERVAL[:months])).to eq('over 3 years')
    expect(distance_of_time_in_words(from_time, from_time + 4 * SECONDS_IN_INTERVAL[:years] + 3 * SECONDS_IN_INTERVAL[:days])).to eq('about 4 years')
    expect(distance_of_time_in_words(Time.now, Time.now)).to eq('less than a minute')
  }
end
