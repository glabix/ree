RSpec.describe 'Ree::Contracts usage in singleton class' do
  subject(:klass) {
    Class.new do
      contract String => 'ok'
      def self.call(name)
        name.to_s
      end
    end
  }

  context 'with right contract' do
    it { expect(klass.call('ok')).to eq 'ok' }
  end

  context 'with violated args contract' do
    it {
      expect { klass.call(:ok) }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contract' do
    it { expect { klass.call('error') }.to raise_error(Ree::Contracts::ReturnContractError) }
  end
end
