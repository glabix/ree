# frozen_string_literal: true

RSpec.describe :offset_to_string do
  link :offset_to_string, from: :ree_datetime

  it {
    expect(offset_to_string(3600)).to eq("+01:00")
    expect(offset_to_string(0)).to eq("+00:00")
    expect(offset_to_string(-3600)).to eq("-01:00")
    expect(offset_to_string(5400)).to eq("+01:30")
    expect(offset_to_string(8461)).to eq("+02:21")
    expect(offset_to_string(86400)).to eq("+24:00")
    expect(offset_to_string(-86400)).to eq("-24:00")

    expect {
      offset_to_string(-86401)
    }.to raise_error(ArgumentError)

    expect {
      offset_to_string(86401)
    }.to raise_error(ArgumentError)
  }
end