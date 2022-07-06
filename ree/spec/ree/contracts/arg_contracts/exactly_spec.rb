RSpec.describe Ree::Contracts::ArgContracts::Exactly do
  class TestStringForExactly < String; end

  subject(:obj) {
    Class.new do
      contract Exactly[TestStringForExactly] => TestStringForExactly
      def call(val)
        val
      end
    end.new
  }

  context 'with valid contract' do
    it {
      val = TestStringForExactly.new
      expect(obj.call(val)).to eq(val)
    }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(String.new) }.to raise_error(
        Ree::Contracts::ContractError,
        "Contract violation for #{obj.class}#call\n\t - val: expected Exactly[TestStringForExactly], got String"
      )
    }
  end
end
