RSpec.describe Ree::Contracts::ArgContracts::SetOf do
  subject(:obj) {
    Class.new do
      contract SetOf[Symbol] => Symbol
      def call(names)
        :ok
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call(Set.new)).to eq :ok }

    it { expect(obj.call(Set.new([:name]))).to eq :ok }

    it { expect(obj.call(Set.new([:name, :name]))).to eq :ok }
  end

  context 'with invalid contract' do
    it { expect { obj.call }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call([]) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call(Set.new(['name'])) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call(Set.new([:name, 'name'])) }.to raise_error Ree::Contracts::ContractError }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract SetOf[Hash, String] => nil
          def call(set); end
        end
      }.to raise_error Ree::Contracts::BadContractError
    }
  end
end
