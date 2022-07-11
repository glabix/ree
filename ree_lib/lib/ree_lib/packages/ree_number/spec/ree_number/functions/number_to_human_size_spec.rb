# frozen_string_literal: true

RSpec.describe :number_to_human_size do
  link :number_to_human_size, from: :ree_number

  context "zero" do
    it {
      expect(number_to_human_size(0)).to eq("0 Bytes")
    }
  end

  context "general" do
    it {
      expect(number_to_human_size(1234)).to eq("1.21 KB")
      expect(number_to_human_size(12345)).to eq("12.1 KB")
      expect(number_to_human_size(1234567)).to eq("1.18 MB")
      expect(number_to_human_size(1234567890)).to eq("1.15 GB")
      expect(number_to_human_size(1234567890123)).to eq("1.12 TB")
      expect(number_to_human_size(1)).to eq("1 Byte")
      expect(number_to_human_size(3.14159265)).to eq("3 Bytes")
      expect(number_to_human_size(123.0)).to eq("123 Bytes")
      expect(number_to_human_size(123)).to eq("123 Bytes")
      expect(number_to_human_size("123")).to eq("123 Bytes")
      expect(number_to_human_size(1.1)).to eq("1 Byte")
      expect(number_to_human_size(10)).to eq("10 Bytes")
      expect(number_to_human_size(444*1024)).to eq("444 KB")
      expect(number_to_human_size(1023*1024*1024)).to eq("1020 MB")
      expect(number_to_human_size(1234567890123456)).to eq("1.1 PB")
      expect(number_to_human_size(1234567890123456789)).to eq("1.07 EB")
      expect(number_to_human_size(1026*1024*1024*1024*1024*1024*1024)).to eq("1030 EB")
      expect(number_to_human_size(3*1024*1024*1024*1024)).to eq("3 TB")
    }
  end

  context "with options hash" do
    it {
      expect(number_to_human_size(1.0123*1024, precision: 2)).to eq("1 KB")
      expect(number_to_human_size(1.0100*1024, precision: 4)).to eq("1.01 KB")
      expect(number_to_human_size(10.000*1024, precision: 4)).to eq("10 KB")
      expect(number_to_human_size(1234567, precision: 2)).to eq("1.2 MB")
      expect(number_to_human_size(3.14159265, precision: 4)).to eq("3 Bytes")
      expect(number_to_human_size(1.00, precision: 4)).to eq("1 Byte")
      expect(number_to_human_size(1.0123*1024, precision: 2)).to eq("1 KB")
      expect(number_to_human_size(1.0100*1024, precision: 4)).to eq("1.01 KB")
      expect(number_to_human_size(10.000*1024, precision: 4)).to eq("10 KB")
      expect(number_to_human_size(1234567890123, precision: 1)).to eq("1 TB")
      expect(number_to_human_size(524288000, precision: 3)).to eq("500 MB")
      expect(number_to_human_size(9961472, precision: 0)).to eq("10 MB")
      expect(number_to_human_size(41010, precision: 1)).to eq("40 KB")
      expect(number_to_human_size(41100, precision: 2)).to eq("40 KB")
      expect(number_to_human_size(3.14159265, precision: 4)).to eq("3 Bytes")
      expect(number_to_human_size(1234567, precision: 2)).to eq("1.2 MB")
      expect(number_to_human_size(1.0123*1024, precision: 2, strip_insignificant_zeros: false)).to eq("1.0 KB")
      expect(number_to_human_size(1.0123*1024, precision: 3, significant: false)).to eq("1.012 KB")
      expect(number_to_human_size(1.0123*1024, precision: 0, significant: true)).to eq("1 KB")
      expect(number_to_human_size(1234567, precision: 2, round_mode: :down)).to eq("1.1 MB")
      expect(number_to_human_size(41100, precision: 1, round_mode: :up)).to eq("50 KB")
    }
  end

  context "with delimiter and separator" do
    it {
      expect(number_to_human_size(1.0123*1024, precision: 3, separator: ",")).to eq("1,01 KB")
      expect(number_to_human_size(1.0100*1024, precision: 4, separator: ",")).to eq("1,01 KB")
      expect(number_to_human_size(1000.1*1024*1024*1024*1024, precision: 5, delimiter: ".", separator: ",")).to eq("1.000,1 TB")
    }
  end
end