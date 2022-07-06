# frozen_string_literal: true
#
require 'date'

RSpec.describe :general_diff do
  link :general_diff, from: :ree_datetime

  it {
    result = general_diff(DateTime.new(2012, 1, 1, 14, 30),
                           DateTime.new(2013, 1, 1, 14, 30))
    expect(result).to eq({:years => 1, :months => 0, :weeks => 0, :days => 1, :hours => 0, :minutes => 0, :seconds => 0 })

    result = general_diff(DateTime.new(2013, 1, 1, 14, 30),
                         DateTime.new(2014, 1, 1, 14, 30))
    expect(result).to eq({:years => 1, :months => 0, :weeks => 0, :days => 0, :hours => 0, :minutes => 0, :seconds => 0 })

    result = general_diff(DateTime.new(2013, 1, 1, 14, 30),
                           DateTime.new(2013, 12, 15, 14, 35), :round_mode => :down)
    expect(result).to eq({:years => 0, :months => 11, :weeks => 2, :days => 4, :hours => 0, :minutes => 5, :seconds => 0 })

    result = general_diff(DateTime.new(2013, 1, 1, 2, 30),
                           DateTime.new(2013, 7, 1, 14, 35), :round_mode => :half_up)
    expect(result).to eq({:years => 0, :months => 6, :weeks => 0, :days => 2, :hours => 0, :minutes => 0, :seconds => 0 })

    result = general_diff(DateTime.new(2013, 1, 1, 2, 30),
                           DateTime.new(2013, 7, 1, 14, 35), :round_mode => :up)
    expect(result).to eq({:years => 1, :months => 0, :weeks => 0, :days => 0, :hours => 0, :minutes => 0, :seconds => 0 })

    result = general_diff(DateTime.new(2013, 1, 1, 2, 30),
                           DateTime.new(2013, 1, 1, 3, 25))
    expect(result).to eq({:years => 0, :months => 0, :weeks => 0, :days => 0, :hours => 1, :minutes => 0, :seconds => 0 })

    result = general_diff(DateTime.new(2013, 1, 1, 2, 30),
                           DateTime.new(2013, 1, 1, 3, 35, 15), round_mode: :half_up)
    expect(result).to eq({:years => 0, :months => 0, :weeks => 0, :days => 0, :hours => 1, :minutes => 5, :seconds => 15 })
  }
end