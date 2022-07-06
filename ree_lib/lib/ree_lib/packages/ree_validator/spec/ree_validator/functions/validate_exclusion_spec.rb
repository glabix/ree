# frozen_string_literal: true

RSpec.describe :validate_exclusion do
  link :validate_exclusion, from: :ree_validator

  context "valid" do
    it {
      expect(validate_exclusion(3, [1, 2], :code)).to eq(true)
      expect(validate_exclusion(3, Set.new([1, 2]), :code)).to eq(true)
      expect(validate_exclusion(3, (1..2), :code)).to eq(true)
    }
  end
  
  context "invalid" do
    it {
      expect {
        validate_exclusion(1, [1, 2], :code)
      }.to raise_error(ReeValidator::ValidateExclusion::ExclusionErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("value should not be one of [1, 2]")
      end
    }

    it {
      expect {
        validate_exclusion(1, Set.new([1, 2]), :code)
      }.to raise_error(ReeValidator::ValidateExclusion::ExclusionErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("value should not be one of [1, 2]")
      end
    }

    it {
      expect {
        validate_exclusion(1, (1..2), :code)
      }.to raise_error(ReeValidator::ValidateExclusion::ExclusionErr) do |e|
        expect(e.extra_code).to eq(:code)
        expect(e.message).to eq("value should not be one of [1, 2]")
      end
    }
  end
end