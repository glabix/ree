RSpec.describe Ree::Contracts::ArgContracts::Eq do
  subject(:obj) {
    Class.new do
      contract Eq['equal_to'.freeze] => String
      def call(val)
        val
      end
    end.new
  }

  context 'with valid contract' do
    it {
      expect(obj.call('equal_to'.freeze)).to eq('equal_to'.freeze)
    }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call('equal_to') }.to raise_error(
        Ree::Contracts::ContractError,
        "Contract violation for #{obj.class}#call\n\t - val: expected Eq[\"equal_to\"], got \"equal_to\""
      )
    }
  end
end
