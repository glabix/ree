RSpec.describe Ree::Contracts::ClassValidator do
  subject(:obj) {
    Class.new do
      contract String => String
      def call(value)
        return if value == 'error'
        value
      end
    end.new
  }

  context 'with right contract' do
    it {
      expect(obj.call('ok')).to eq 'ok'
    }

    it {
      expect(obj.call(Class.new(String).new)).to eq ''
    }
  end

  context 'with violated args contract' do
    it {
      expect { obj.call(1) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call(String) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call(:ok) }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contact' do
    it {
      expect { obj.call('error') }.to raise_error(Ree::Contracts::ReturnContractError)
    }
  end
end
