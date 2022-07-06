# frozen_string_literal: true

package_require('ree_datetime/functions/minutes_diff')

RSpec.describe :minutes_diff do
  link :minutes_diff, from: :ree_datetime


  let(:err_result) {minutes_diff(Time.new(2040, 1, 1,2, 15),
    Time.new(2012, 1, 1, 2, 30))}

  it {
    expect{ err_result }.to raise_error(ArgumentError)

    result = minutes_diff(Time.new(2012, 1, 1,2, 15),
                           Time.new(2012, 1, 1, 2, 30))
    expect(result).to eq(15)

    result = minutes_diff(Time.new(2012, 1, 1,10, 0),
                           Time.new(2012, 1, 2, 10, 0))
    expect(result).to eq(1440)

    result = minutes_diff(Time.new(2012, 1, 1,10, 0),
                           Time.new(2012, 1, 2, 11, 51))
    expect(result).to eq(1551)

    result = minutes_diff(Time.new(2012, 1, 1,10, 0),
                           Time.new(2012, 1, 2, 11, 51))
    expect(result).to eq(1551)

    result = minutes_diff(Time.new(2012, 1, 1,10, 0),
                           Time.new(2012, 1, 2, 11, 51, 31))
    expect(result).to eq(1552)

    result = minutes_diff(Time.new(2012, 1, 1,10, 0),
                           Time.new(2012, 1, 1, 11, 51, 30),
      round_mode: :half_down)
    expect(result).to eq(111)

    result = minutes_diff(Date.new(2012, 1, 1),
                           Time.new(2012, 1, 1, 11, 51, 30),
      round_mode: :half_up)
    expect(result).to eq(712)

  }
end
