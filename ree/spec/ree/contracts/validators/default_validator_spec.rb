RSpec.describe Ree::Contracts::DefaultValidator do
  subject(:obj) {
    Class.new do
      attr_accessor :return_value

      contract 'ok' => 'ok'
      def call(value)
        self.return_value ||= value
      end
    end.new
  }

  context 'with right contract' do
    it {
      expect(obj.call('ok')).to eq 'ok'
    }
  end

  context 'with violated args contract' do
    it {
      expect { obj.call('not ok') }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contact' do
    it {
      obj.return_value = 'error'
      expect { obj.call('ok') }.to raise_error(Ree::Contracts::ReturnContractError)
    }
  end
end
