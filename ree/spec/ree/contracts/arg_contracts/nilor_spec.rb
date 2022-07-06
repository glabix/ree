RSpec.describe Ree::Contracts::ArgContracts::Nilor do
  subject(:obj) {
    Class.new do
      contract Nilor[String] => Nilor[String]
      def call(name)
        name
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call(nil)).to eq nil }

    it { expect(obj.call('ok')).to eq 'ok' }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(1) }.to raise_error(Ree::Contracts::ContractError)
    }
  end
end
