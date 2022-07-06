RSpec.describe Ree::Contracts::ArgContracts::Optblock do
  subject(:obj) {
    Class.new do
      contract Optblock => Symbol
      def call(&blk)
        blk&.call || :no_block
      end

      contract Optblock => Symbol
      def call_with_yield(&blk)
        return :no_block unless block_given?
        yield
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call { :ok }).to eq :ok }

    it { expect(obj.call(&-> { :ok })).to eq :ok }

    it { expect(obj.call).to eq :no_block }

    it { expect(obj.call_with_yield { :ok }).to eq :ok }

    it { expect(obj.call_with_yield(&-> { :ok })).to eq :ok }

    it { expect(obj.call_with_yield).to eq :no_block }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(1) }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call
        \t - given 1, expected 0
        MSG
      )
    }

    it {
      expect { obj.call_with_yield(1) }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call_with_yield
        \t - given 1, expected 0
        MSG
      )
    }
  end
end
