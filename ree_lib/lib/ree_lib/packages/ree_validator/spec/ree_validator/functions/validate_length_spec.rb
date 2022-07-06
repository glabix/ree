# frozen_string_literal: true

RSpec.describe :validate_length do
  link :validate_length, from: :ree_validator

  context "valid" do
    it {
      expect(validate_length([1], :code, min: 1)).to eq(true)
      expect(validate_length([1], :code, max: 1)).to eq(true)
      expect(validate_length([1], :code, equal_to: 1)).to eq(true)
      expect(validate_length([1], :code, not_equal_to: 0)).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_length([1], :code, min: 2)
      }.to raise_error(ReeValidator::ValidateLength::MinLengthErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("length can not be less than 2")
      end
    }

    it {
      expect {
        validate_length([1, 2], :code, max: 1)
      }.to raise_error(ReeValidator::ValidateLength::MaxLengthErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("length can not be more than 1")
      end
    }

    it {
      expect {
        validate_length([1, 2], :code, equal_to: 1)
      }.to raise_error(ReeValidator::ValidateLength::EqualToLengthErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("length should be equal to 1")
      end
    }

    it {
      expect {
        validate_length([1, 2], :code, not_equal_to: 2)
      }.to raise_error(ReeValidator::ValidateLength::NotEqualToLengthErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("length should not be equal to 2")
      end
    }
  end
end