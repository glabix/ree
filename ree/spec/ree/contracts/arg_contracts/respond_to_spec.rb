RSpec.describe Ree::Contracts::ArgContracts::RespondTo do
  subject(:obj) {
    Class.new do
      contract RespondTo[:empty?, :to_s] => Bool
      def call(name)
        name.empty?
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call('')).to eq true }

    it { expect(obj.call('ok')).to eq false }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(1) }.to raise_error(Ree::Contracts::ContractError)
    }
  end
end
