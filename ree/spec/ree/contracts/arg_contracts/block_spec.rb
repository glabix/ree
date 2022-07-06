RSpec.describe Ree::Contracts::ArgContracts::Block do
  subject(:obj) {
    Class.new do
      contract Block => Symbol
      def call(&blk)
        blk.call
      end

      contract Block => Nilor[Symbol]
      def call_with_yield(&blk)
        yield if block_given?
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call { :ok }).to eq :ok }

    it { expect(obj.call(&-> { :ok })).to eq :ok }

    it { expect(obj.call_with_yield { :ok }).to eq :ok }

    it { expect(obj.call_with_yield(&-> { :ok })).to eq :ok }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(1) }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call
        \t - missing required block
        MSG
      )
    }

    it {
      expect { obj.call }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call
        \t - missing required block
        MSG
      )
    }

    it {
      expect { obj.call_with_yield(1) }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call_with_yield
        \t - missing required block
        MSG
      )
    }

    it {
      expect { obj.call_with_yield }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call_with_yield
        \t - missing required block
        MSG
      )
    }
  end
end
