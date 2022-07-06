# frozen_string_literal: true

RSpec.describe :seconds_diff do
  link :seconds_diff, from: :ree_datetime

  let(:err_result) {seconds_diff(Time.new(2040, 1, 1,2, 15),
    Time.new(2012, 1, 1, 2, 30))}

  it {
    expect{ err_result }.to raise_error(ArgumentError)

    result = seconds_diff(Time.new(2012, 1, 1,2, 15),
      Time.new(2013, 1, 1, 2, 15))
    expect(result).to eq(31_622_400)

  }
end
