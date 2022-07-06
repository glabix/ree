# frozen_string_literal: true

RSpec.describe :number_to_human do
  link :number_to_human, from: :ree_number

  context 'general' do
    it {
      expect(number_to_human(-123)).to eq("-1.23 Hundred")
      expect(number_to_human(-0.5)).to eq("-5 Tenth")
      expect(number_to_human(0)).to eq("0")
      expect(number_to_human(0.5)).to eq("5 Tenth")
      expect(number_to_human(123)).to eq("1.23 Hundred")
      expect(number_to_human(1234)).to eq("1.23 Thousand")
      expect(number_to_human(12345)).to eq("12.3 Thousand")
      expect(number_to_human(1234567)).to eq("1.23 Million")
      expect(number_to_human(1234567890)).to eq("1.23 Billion")
      expect(number_to_human(1234567890123)).to eq("1.23 Trillion")
      expect(number_to_human(1234567890123456)).to eq("1.23 Quadrillion")    
      expect(number_to_human(1234567890123456789)).to eq("1230 Quadrillion")      
    }
  end

  context "precision, separator, round mode" do
    it {
      expect(number_to_human(489939, precision: 2)).to eq("490 Thousand")
      expect(number_to_human(489939, precision: 4)).to eq("489.9 Thousand")
      expect(number_to_human(489000, precision: 4)).to eq("489 Thousand")
      expect(number_to_human(489000, precision: 4, strip_insignificant_zeros: false)).to eq("489.0 Thousand")
      expect(number_to_human(1234567, precision: 1, significant: false, separator: ",")).to eq("1,2 Million")
      expect(number_to_human(1234567, precision: 4, significant: false)).to eq("1.2346 Million")
      expect(number_to_human(1234567, precision: 0, significant: true, separator: ",")).to eq("1 Million") 
      expect(number_to_human(489939, precision: 2, round_mode: :down)).to eq("480 Thousand")
    }
  end

  context "large numbers" do
    it {
      expect(number_to_human(999999)).to eq("1 Million")
      expect(number_to_human(999999999)).to eq("1 Billion")
    }
  end

  context "custom format and units" do
    it {
      expect(number_to_human(123456, format: "%n times %u")).to eq("123 times Thousand")
      expect(number_to_human(1230, units: "distance")).to eq("1.23 km")
      expect(number_to_human(1234567, units: "volume")).to eq("1.23 m3")
    }
  end
end