# frozen_string_literal: true

RSpec.describe :validate_regexp do
  link :validate_regexp, from: :ree_validator

  context "valid" do
    it {
      expect(validate_regexp("string", /string/)).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_regexp('string', /$sss^/)
      }.to raise_error(ReeValidator::ValidateRegexp::RegexpErr) do |e|
        expect(e.message).to eq("value does not match regexp /$sss^/")
      end
    }

    it {
      expect {
        validate_regexp('string', /$sss^/, Class.new(StandardError).new("message"))
      }.to raise_error(StandardError) do |e|
        expect(e.message).to eq("message")
      end
    }
  end
end