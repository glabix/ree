RSpec.describe 'Ree::Contracts usage in singleton subclass' do
  subject(:subklass) {
    Class.new(klass) do
      contract String => 'ok'
      def self.new_call(name)
        name.to_s
      end
    end
  }

  let(:klass) {
    Class.new do
      contract String => 'ok'
      def self.call(name)
        name.to_s
      end
    end
  }

  context 'with right contract' do
    it { expect(subklass.call('ok')).to eq 'ok' }

    it { expect(subklass.new_call('ok')).to eq 'ok' }
  end

  context 'with violated args contract' do
    it {
      expect { subklass.call(:ok) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { subklass.new_call(:ok) }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contract' do
    it {
      expect { subklass.call('error') }.to raise_error(Ree::Contracts::ReturnContractError)
    }

    it {
      expect { subklass.new_call('error') }.to raise_error(Ree::Contracts::ReturnContractError)
    }
  end
end
