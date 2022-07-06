# frozen_string_literal: true

RSpec.describe :number_to_currency do
  link :number_to_currency, from: :ree_number

  it {
    expect(number_to_currency(1234567890.50)).to eq("$1,234,567,890.50")
    expect(number_to_currency("1234567890.50")).to eq("$1,234,567,890.50")
    expect(number_to_currency(1234567890.506)).to eq("$1,234,567,890.51")
    expect(number_to_currency(-1234567890.50)).to eq("-$1,234,567,890.50")
    expect(number_to_currency("-1,234,567,890.50")).to eq("-$1,234,567,890.50")
    expect(number_to_currency(-1234567890.50, format: "%u %n")).to eq("-$ 1,234,567,890.50")
    expect(number_to_currency(-1234567890.50, negative_format: "(%u%n)")).to eq("($1,234,567,890.50)")
    expect(number_to_currency(1234567891.50, precision: 0)).to eq("$1,234,567,892")
    expect(number_to_currency(1234567890.50, precision: 1)).to eq("$1,234,567,890.5")
    expect(number_to_currency(123987, precision: 4, significant: true)).to eq("$124,000")
    expect(number_to_currency(1234567890.50, unit: "&pound")).to eq("&pound1,234,567,890.50")
    expect(number_to_currency(1234567890.50, unit: "&pound;", separator: ",", delimiter: "")).to eq("&pound;1234567890,50")
    expect(number_to_currency(1234567891.50, precision: 0, round_mode: :down)).to eq("$1,234,567,891")

    expect(
      number_to_currency(
        1234567890.50, 
        unit: "&pound;", 
        separator: ",", 
        delimiter: "", 
        strip_insignificant_zeros: true
      )
    ).to eq("&pound;1234567890,5")

    expect(number_to_currency("1234567890.50", unit: "K&#269;", format: "%n %u")).to eq("1,234,567,890.50 K&#269;")

    expect(
      number_to_currency(
        "-1234567890.50", 
        unit: "K&#269;", 
        format: "%n %u", 
        negative_format: "%n - %u"
      )
    ).to eq("1,234,567,890.50 - K&#269;")

    expect(number_to_currency(+0.0, unit: "", negative_format: "(%n)")).to eq("0.00")
    expect(number_to_currency(-0.456789, precision: 0)).to eq("$0")
    expect(number_to_currency(-0.0456789, precision: 1)).to eq("$0.0")
    expect(number_to_currency(-0.00456789, precision: 2)).to eq("$0.00")
    expect(number_to_currency(-0.5, precision: 0)).to eq("-$1")
    expect(number_to_currency("1,11")).to eq("$1,11")
    expect(number_to_currency(-0.0)).to eq("$0.00")
    expect(number_to_currency("-0.0")).to eq("$0.00")
  }
end