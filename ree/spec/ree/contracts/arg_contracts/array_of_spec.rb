RSpec.describe Ree::Contracts::ArgContracts::ArrayOf do
  subject(:obj) {
    Class.new do
      contract ArrayOf[Symbol] => Symbol
      def call(names)
        :ok
      end
    end.new
  }

  let(:array_of_any) {
    Class.new do
      contract ArrayOf[Any] => Symbol
      def call(names)
        :ok
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call([])).to eq :ok }

    it { expect(obj.call([:name])).to eq :ok }

    it { expect(obj.call([:name, :name])).to eq :ok }

    it { expect(array_of_any.call([:name, :name])).to eq :ok }
  end

  context 'with invalid contract' do
    it { expect { obj.call }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call(Set.new) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call(['name']) }.to raise_error Ree::Contracts::ContractError }

    it { expect { obj.call([:name, 'name']) }.to raise_error Ree::Contracts::ContractError }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract ArrayOf[Hash, String] => nil
          def call(ary); end
        end
      }.to raise_error Ree::Contracts::BadContractError
    }
  end
end
