RSpec.describe 'Ree::Contracts usage in module' do
  let(:mod) {
    Module.new do
      include Ree::Contracts::Core

      contract String => 'ok'
      def self.call(name)
        name
      end

      contract Symbol => :ok
      def call(name)
        name
      end
    end
  }

  let(:klass) {
    Class.new.tap { |klass|
      klass.include(mod)
      klass.extend(mod)
    }
  }

  let(:obj) {
    klass.new
  }

  context 'with right contract' do
    it { expect(mod.call('ok')).to eq 'ok' }

    it { expect(klass.call(:ok)).to eq :ok }

    it { expect(obj.call(:ok)).to eq :ok }
  end

  context 'with violated args contract' do
    it {
      expect { mod.call(:ok) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { klass.call('ok') }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call('ok') }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contract' do
    it {
      expect { mod.call('error') }.to raise_error(Ree::Contracts::ReturnContractError)
    }

    it {
      expect { klass.call(:error) }.to raise_error(Ree::Contracts::ReturnContractError)
    }

    it {
      expect { obj.call(:error) }.to raise_error(Ree::Contracts::ReturnContractError)
    }
  end
end
