RSpec.describe Ree::Contracts::ArrayValidator do
  subject(:obj) {
    Class.new do
      contract [String, Symbol] => [String, :ok]
      def call(value)
        value
      end
    end.new
  }

  context 'with right contract' do
    it {
      expect(obj.call(['ok', :ok])).to eq ['ok', :ok]
    }
  end

  context 'with violated args contract' do
    it {
      expect { obj.call([]) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call(['ok']) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call(['ok', 'ok']) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call(['ok', :ok, 'ok']) }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contact' do
    it {
      expect { obj.call(['ok', :error]) }.to raise_error(Ree::Contracts::ReturnContractError)
    }
  end
end
