RSpec.describe Ree::Contracts::ArgContracts::Bool do
  subject(:obj) {
    Class.new do
      contract Bool => Bool
      def call(flag)
        flag
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call(true)).to eq true }

    it { expect(obj.call(false)).to eq false }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(1) }.to raise_error(Ree::Contracts::ContractError)
    }
  end
end
