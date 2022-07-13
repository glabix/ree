# frozen_string_literal: true

RSpec.describe :validate_presence do
  link :validate_presence, from: :ree_validator

  context "valid" do
    it {
      expect(validate_presence("string")).to eq(true)
      expect(validate_presence([1])).to eq(true)
      expect(validate_presence({id: 1})).to eq(true)
      expect(validate_presence(Set.new([1]))).to eq(true)
      expect(validate_presence(Object.new)).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_presence([])
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr) do |e|
        expect(e.message).to eq("can not be blank")
      end
    }

    it {
      expect {
        validate_presence(nil)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence("")
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence("  ")
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence(Set.new([]))
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence({}, Class.new(StandardError))
      }.to raise_error(StandardError)
    }
  end
end