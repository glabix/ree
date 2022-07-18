# frozen_string_literal: true

RSpec.describe :validate_length do
  link :validate_length, from: :ree_validator

  context "valid" do
    it {
      expect(validate_length([1], min: 1)).to eq(true)
      expect(validate_length([1], max: 1)).to eq(true)
      expect(validate_length([1], equal_to: 1)).to eq(true)
      expect(validate_length([1], not_equal_to: 0)).to eq(true)
    }
  end

  context "invalid" do
    it {
      expect {
        validate_length([1], min: 2)
      }.to raise_error(ReeValidator::ValidateLength::LenthErr) do |e|
        expect(e.message).to eq("length can not be less than 2")
      end
    }

    it {
      expect {
        validate_length([1, 2], max: 1)
      }.to raise_error(ReeValidator::ValidateLength::LenthErr) do |e|
        expect(e.message).to eq("length can not be more than 1")
      end
    }

    it {
      expect {
        validate_length([1, 2], equal_to: 1)
      }.to raise_error(ReeValidator::ValidateLength::LenthErr) do |e|
        expect(e.message).to eq("length should be equal to 1")
      end
    }

    it {
      expect {
        validate_length([1, 2], Class.new(StandardError).new("message"), not_equal_to: 2)
      }.to raise_error(StandardError) do |e|
        expect(e.message).to eq("message")
      end
    }
  end
end