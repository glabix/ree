RSpec.describe 'Ree::Contracts optional args' do
  context 'with right contract' do
    subject(:obj) {
      Class.new do
        contract String, Nilor[String] => String
        def call(arg, opt_arg = nil)
          'ok'
        end
      end.new
    }

    it { expect(obj.call('arg', 'opt_arg')).to eq 'ok' }

    it { expect(obj.call('arg')).to eq 'ok' }
  end

  context 'with violated args contract' do
    subject(:obj) {
      Class.new do
        contract String, Nilor[String] => String
        def call(name, opt_name = nil)
          'ok'
        end
      end.new
    }

    it {
      expect { obj.call(:arg) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call('arg', :opt_arg) }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with invalid contract' do
    it {
      expect {
        Class.new do
          contract String => nil
          def call(name, opt_name = nil); end
        end.new
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end
end
