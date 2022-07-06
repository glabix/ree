# frozen_string_literal: true

RSpec.describe :number_to_phone do
  link :number_to_phone, from: :ree_number

  it {
    expect(number_to_phone(5551234)).to eq("555-1234")
    expect(number_to_phone(8005551212)).to eq("800-555-1212")
    expect(number_to_phone(8005551212, area_code: true)).to eq("(800) 555-1212")
    expect(number_to_phone(8005551212, delimiter: " ")).to eq("800 555 1212")
    expect(number_to_phone(5551234, delimiter: ".")).to eq("555.1234")
    expect(number_to_phone(5551234, country_code: 375, delimiter: "")).to eq("+375551234")
    expect(number_to_phone(5551234, country_code: 375)).to eq("+375-555-1234")
    expect(number_to_phone(225551212)).to eq("22-555-1212")
    expect(number_to_phone(225551212, country_code: 45)).to eq("+45-22-555-1212")
    expect(number_to_phone(13312345678, pattern: /(\d{3})(\d{4})(\d{4})/)).to eq("133-1234-5678")
    expect(number_to_phone(8005551212, area_code: true, extension: 123)).to eq("(800) 555-1212 x 123")
    expect(number_to_phone(
      8005551212, 
      country_code: 7, 
      area_code: true, 
      extension: 123, 
      delimiter: " "
      )
    ).to eq("+7 (800) 555 1212 x 123")
  }
end