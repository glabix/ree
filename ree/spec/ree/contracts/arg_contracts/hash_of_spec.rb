RSpec.describe Ree::Contracts::ArgContracts::HashOf do
  subject(:obj) {
    Class.new do
      contract HashOf[Symbol, String] => Symbol
      def call(dict)
        :ok
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call({})).to eq :ok }

    it { expect(obj.call({ name: 'name' })).to eq :ok }

    it { expect(obj.call({ name: 'name', other: 'other' })).to eq :ok }
  end

  context 'with invalid contract' do
    it { expect { obj.call }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call([]) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call({ 'name' => 'name' }) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call({ :name => :name }) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call({ name: 'name', other: :other }) }.to raise_error Ree::Contracts::ContractError }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract HashOf[] => nil
          def call(hsh); end
        end
      }.to raise_error Ree::Contracts::BadContractError
    }

    it {
      expect {
        Class.new do
          contract HashOf[String] => nil
          def call(hsh); end
        end
      }.to raise_error Ree::Contracts::BadContractError
    }

    it {
      expect {
        Class.new do
          contract HashOf[Symbol, String, Integer] => nil
          def call(hsh); end
        end
      }.to raise_error Ree::Contracts::BadContractError
    }
  end
end
