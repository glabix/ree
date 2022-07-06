# frozen_string_literal: true

RSpec.describe :hours_diff do
  link :hours_diff, from: :ree_datetime

  let(:err_result) {hours_diff(Time.new(2040, 1, 1,2, 15),
    Time.new(2012, 1, 1, 2, 30))}

  it {
    expect{ err_result }.to raise_error(ArgumentError)

    result = hours_diff(Time.new(2012, 1, 1,2, 15),
                         Time.new(2012, 1, 1, 2, 30))
    expect(result).to eq(0)

    result = hours_diff(Time.new(2012, 1, 1,10, 0),
                         Time.new(2012, 1, 2, 10, 0))
    expect(result).to eq(24)

    result = hours_diff(Time.new(2012, 1, 1,2, 15),
                         Time.new(2012, 1, 1, 4, 30))
    expect(result).to eq(2)

    result = hours_diff(Time.new(2013, 1, 1,10, 0),
                         Time.new(2013, 1, 2, 11, 30), :round_mode => :half_up)
    expect(result).to eq(26)

  }
end
