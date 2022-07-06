RSpec.describe Ree::Contracts::ArgContracts::RangeOf do
  subject(:obj) {
    Class.new do
      contract RangeOf[Integer] => RangeOf[Integer]
      def call(value)
        value
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call(1..5)).to eq(1..5) }
  end

  context 'with invalid contract' do
    it {
      begin
        obj.call((1.1)..(1.5))
      rescue => e
        p e.message
      end
      expect { obj.call((1.1)..(1.5)) }.to raise_error(
        Ree::Contracts::ContractError,
        "Contract violation for #{obj.class}#call\n\t - value:\n\t   - value.begin: expected Integer, got Float => 1.1\n\t   - value.end: expected Integer, got Float => 1.5"
      )
    }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract RangeOf[Integer, Integer] => None
          def call(value); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end
end
