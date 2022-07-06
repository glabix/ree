# frozen_string_literal: true

RSpec.describe :validate_presence do
  link :validate_presence, from: :ree_validator

  context "valid" do
    it {
      expect(validate_presence("string", :string)).to eq(true)
      expect(validate_presence([1], :array)).to eq(true)
      expect(validate_presence({id: 1}, :hash)).to eq(true)
      expect(validate_presence(Set.new([1]), :code)).to eq(true)
      expect(validate_presence(Object.new, :code)).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_presence([], :code)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("can not be blank")
      end
    }

    it {
      expect {
        validate_presence(nil, :code)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence("", :code)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence("  ", :code)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence(Set.new([]), :code)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }

    it {
      expect {
        validate_presence({}, :code)
      }.to raise_error(ReeValidator::ValidatePresence::PresenceErr)
    }
  end
end