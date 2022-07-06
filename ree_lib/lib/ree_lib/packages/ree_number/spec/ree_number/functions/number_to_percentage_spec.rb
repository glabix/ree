# frozen_string_literal: true

RSpec.describe :number_to_percentage do
  link :number_to_percentage, from: :ree_number

  it {
    expect(number_to_percentage(100)).to eq("100.000%")
    expect(number_to_percentage(Float::NAN)).to eq("NaN%")
    expect(number_to_percentage(Float::INFINITY)).to eq("Inf%")
    
    expect(number_to_percentage(Float::NAN, precision: 1)).to eq("NaN%")
    expect(number_to_percentage(Float::INFINITY, precision: 1)).to eq("Inf%")
    expect(number_to_percentage("-0.13", format: "%n %", precision: 2)).to eq("-0.13 %")
    expect(number_to_percentage(1000, format: "%n  %")).to eq("1000.000  %")
    expect(number_to_percentage(123.400, precision: 3, strip_insignificant_zeros: true)).to eq("123.4%")
    expect(number_to_percentage(1.25, precision: 2, significant: true)).to eq("1.3%")
    expect(number_to_percentage(302.0574, precision: 2, round_mode: :down)).to eq("302.05%")
  }
end