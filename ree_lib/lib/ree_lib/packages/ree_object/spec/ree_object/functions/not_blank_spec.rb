# frozen_string_literal: true

RSpec.describe :not_blank do
  link :not_blank, from: :ree_object

  context "blank" do
    it {
      expect(not_blank(nil)). to be false
      expect(not_blank(false)). to be false
      expect(not_blank("")). to be false
      expect(not_blank("   ")). to be false
      expect(not_blank("  \n\t  \r ")). to be false
      expect(not_blank("  ")). to be false
      expect(not_blank("\u00a0")). to be false
      expect(not_blank([])). to be false
      expect(not_blank({})). to be false
      expect(not_blank(" ".encode("UTF-16LE"))).to be false
    }
  end

  context "not blank" do
    it {
      expect(not_blank(Object.new)).to be true
      expect(not_blank(true)).to be true
      expect(not_blank(0)).to be true
      expect(not_blank(1)).to be true
      expect(not_blank([nil])).to be true
      expect(not_blank({ nil => 0 })).to be true
      expect(not_blank(Time.now)).to be true
      expect(not_blank("my value".encode("UTF-16LE"))).to be true
    }
  end
end