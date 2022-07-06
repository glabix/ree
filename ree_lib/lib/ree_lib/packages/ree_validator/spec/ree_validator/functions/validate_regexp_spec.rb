# frozen_string_literal: true

RSpec.describe :validate_regexp do
  link :validate_regexp, from: :ree_validator

  context "valid" do
    it {
      expect(validate_regexp("string", /string/, :code)).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_regexp('string', /$sss^/, :code)
      }.to raise_error(ReeValidator::ValidateRegexp::RegexpErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("value does not match regexp /$sss^/")
      end
    }
  end
end