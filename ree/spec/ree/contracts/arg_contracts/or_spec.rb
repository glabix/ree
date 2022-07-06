RSpec.describe Ree::Contracts::ArgContracts::Or do
  subject(:obj) {
    Class.new do
      contract Or[String, Symbol] => Symbol
      def call(name)
        name.to_sym
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call(:ok)).to eq :ok }

    it { expect(obj.call('ok')).to eq :ok }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(1) }.to raise_error(Ree::Contracts::ContractError)
    }
  end
end
