# frozen_string_literal: true

RSpec.describe :days_diff do
  link :days_diff, from: :ree_datetime

  let(:err_result) {days_diff(Time.new(2040, 1, 1,2, 15),
    Time.new(2012, 1, 1, 2, 30))}

  it {
    expect{ err_result }.to raise_error(ArgumentError)

    result = days_diff(Time.new(2012, 1, 1,2, 15),
                        Time.new(2012, 1, 2, 2, 30))
    expect(result).to eq(1)

    result = days_diff(Time.new(2012, 1, 1,10, 0),
                        Time.new(2012, 2, 15, 10, 0))
    expect(result).to eq(45)

    result = days_diff(Time.new(2012, 2, 1,2, 15),
                        Time.new(2012, 2, 16, 16, 15), :round_mode => :half_up)
    expect(result).to eq(16)

    result = days_diff(Time.new(2013, 1, 1,10, 0),
                        Time.new(2014, 1, 1, 10, 0))
    expect(result).to eq(365)

  }
end
