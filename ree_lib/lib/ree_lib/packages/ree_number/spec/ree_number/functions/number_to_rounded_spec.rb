# frozen_string_literal: true

RSpec.describe :number_to_rounded do
  link :number_to_rounded, from: :ree_number

  context "default presicion" do
    it {
      expect(number_to_rounded(-111.2346)).to eq("-111.235")
      expect(number_to_rounded(111.2346)).to eq("111.235")
      expect(number_to_rounded("111.2346")).to eq("111.235")
      expect(number_to_rounded(Float::NAN)).to eq("NaN")   
      expect(number_to_rounded(Float::INFINITY)).to eq("Inf")
      expect(number_to_rounded(-Float::INFINITY)).to eq("-Inf")
    }
  end

  context "custom precision" do
    it {
      expect(number_to_rounded(111.2346, precision: 20)).to eq("111.23460000000000000000")
      expect(number_to_rounded("111.2346", precision: 20)).to eq("111.23460000000000000000")
      expect(number_to_rounded(31.825, precision: 2)).to eq("31.83")
      expect(number_to_rounded(111.2346, precision: 2)).to eq("111.23")
      expect(number_to_rounded(111, precision: 2)).to eq("111.00")
      expect(number_to_rounded("31.825", precision: 2)).to eq("31.83")
      expect(number_to_rounded(0.001, precision: 5)).to eq("0.00100")
      expect(number_to_rounded(0.00111, precision: 3)).to eq("0.001")
      expect(number_to_rounded(9.995, precision: 2)).to eq("10.00")
      expect(number_to_rounded(10.995, precision: 2)).to eq("11.00")
      expect(number_to_rounded(-0.001, precision: 2)).to eq("0.00")
      expect(number_to_rounded(Rational(1112346, 10000), precision: 20)).to eq("111.23460000000000000000")
      expect(number_to_rounded("111.2346", precision: 100)).to eq("111.2346" + "0" * 96)
      expect(number_to_rounded(Rational(1112346, 10000), precision: 4)).to eq("111.2346")
      expect(number_to_rounded(Rational(0, 1), precision: 2)).to eq("0.00")
      expect(number_to_rounded(111.2346, precision: 2, round_mode: :up)).to eq("111.24")
    }    
  end

  context "zero presicion" do 
    it {
      expect(number_to_rounded((32.6751 * 100.00), precision: 0)).to eq("3268")
      expect(number_to_rounded(111.50, precision: 0)).to eq("112")
      expect(number_to_rounded(1234567891.50, precision: 0)).to eq("1234567892")
      expect(number_to_rounded(0, precision: 0)).to eq("0")
    }
  end

  context "significant  = true" do
    it {
      expect(number_to_rounded(123987, precision: 3, significant: true)).to eq("124000")
      expect(number_to_rounded(1, precision: 1, significant: true)).to eq("1")
      expect(number_to_rounded(5.3929, precision: 7, significant: true)).to eq("5.392900")
      expect(number_to_rounded(5.3929, precision: 7, significant: true)).to eq("5.392900")
      expect(number_to_rounded(10.995, precision: 3, significant: true)).to eq("11.0")
      expect(number_to_rounded(0.0001, precision: 3, significant: true)).to eq("0.000100")
      expect(number_to_rounded(9775, precision: 20, significant: true)).to eq("9775.0000000000000000")
      expect(number_to_rounded(Rational(9775, 100), precision: 20, significant: true)).to eq("97.750000000000000000")
      expect(number_to_rounded(9775, precision: 100, significant: true)).to eq("9775." + "0" * 96)
      expect(number_to_rounded(Rational(9772,100), precision: 3, significant: true)).to eq("97.7")
      expect(number_to_rounded(123987, precision: 3, significant: true, round_mode: :down)).to eq("123000")
    }
  end

  context "significant = true, zero precision" do
    it {
      expect(number_to_rounded(123.987, precision: 0, significant: true)).to eq("124")
      expect(number_to_rounded(12, precision: 0, significant: true)).to eq("12")
      expect(number_to_rounded("12.3", precision: 0, significant: true)).to eq("12")
    }
  end

  context "strip_unsignuficant_zeros = true" do
    it {
      expect(number_to_rounded(9775.43, precision: 4, strip_insignificant_zeros: true)).to eq("9775.43") 
      expect(number_to_rounded(9775.2, precision: 6, strip_insignificant_zeros: true)).to eq("9775.2")  
      expect(number_to_rounded(0, precision: 4, significant: true, strip_insignificant_zeros: true)).to eq("0")  
      expect(number_to_rounded(5.3929, precision: 10, significant: true, strip_insignificant_zeros: true)).to eq("5.3929")
    }
  end
end