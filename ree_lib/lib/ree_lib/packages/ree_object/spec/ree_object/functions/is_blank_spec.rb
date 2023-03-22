# frozen_string_literal: true

RSpec.describe :is_blank do
  link :is_blank, from: :ree_object

  context "blank" do
    it {
      expect(is_blank(nil)). to be true
      expect(is_blank(false)). to be true
      expect(is_blank("")). to be true
      expect(is_blank("   ")). to be true
      expect(is_blank("  \n\t  \r ")). to be true
      expect(is_blank("  ")). to be true
      expect(is_blank("\u00a0")). to be true
      expect(is_blank([])). to be true
      expect(is_blank({})). to be true
      expect(is_blank(" ".encode("UTF-16LE"))).to be true
    }
  end

  context "not blank" do
    it {
      expect(is_blank(Object.new)).to be false
      expect(is_blank(true)).to be false
      expect(is_blank(0)).to be false
      expect(is_blank(1)).to be false
      expect(is_blank([nil])).to be false
      expect(is_blank({ nil => 0 })).to be false
      expect(is_blank(Time.now)).to be false
      expect(is_blank("my value".encode("UTF-16LE"))).to be false
    }
  end
end