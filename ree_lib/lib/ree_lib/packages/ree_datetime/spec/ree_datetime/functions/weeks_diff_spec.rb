# frozen_string_literal: true

RSpec.describe :weeks_diff do
  link :weeks_diff, from: :ree_datetime

  let(:err_result) {weeks_diff(Time.new(2040, 1, 1,2, 15),
    Time.new(2012, 1, 1, 2, 30))}

  it {
    expect{ err_result }.to raise_error(ArgumentError)

    result = weeks_diff(Time.new(2012, 1, 1,2, 15),
                         Time.new(2012, 2, 1, 2, 30))
    expect(result).to eq(4)

    result = weeks_diff(Time.new(2012, 1, 1,10, 0),
                         Time.new(2012, 2, 15, 10, 0))
    expect(result).to eq(6)

    result = weeks_diff(Time.new(2012, 2, 1,2, 15),
                         Time.new(2012, 2, 16, 2, 15), :round_mode => :half_up)
    expect(result).to eq(2)

    result = weeks_diff(Time.new(2013, 1, 1,10, 0),
                         Time.new(2013, 12, 30, 11, 30))
    expect(result).to eq(52)

  }
end
