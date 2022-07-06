RSpec.describe 'Ree::Contracts kwargs' do
  subject(:obj) {
    Class.new do
      contract Symbol, String => [Symbol, String]
      def call(sym:, str:)
        [sym, str]
      end

      contract Symbol, Ksplat[RestKeys => Any] => [Symbol, Hash]
      def call_with_splat(sym:, **splat)
        [sym, splat]
      end
    end.new
  }

  context 'with right contract' do
    it { expect(obj.call(sym: :sym, str: 'str')).to eq [:sym, 'str'] }

    it { expect(obj.call(str: 'str', sym: :sym)).to eq [:sym, 'str'] }

    it { expect(obj.call_with_splat(sym: :sym, splat: :splat)).to eq [:sym, { splat: :splat }] }
  end

  context 'with wrong contract' do
    it {
      expect { obj.call(sym: 'str', str: 'str') }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { obj.call(str: 'str') }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call
        \t - missing keyword arg `sym`
        MSG
      )
    }

    it {
      expect { obj.call(sym: :sym, str: 'str', missing: 'missing') }.to raise_error(
        Ree::Contracts::ContractError,
        <<~MSG.chomp
        Wrong number of arguments for #{obj.class}#call
        \t - unknown keyword arg `missing`
        MSG
      )
    }

    it {
      expect { obj.call_with_splat(sym: 'str') }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with bad contract' do
    it {
      klass = Class.new
      expect {
        klass.class_eval do
          contract String => nil
          def call(name:, miss_kwarg:); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - contract count is not equal to argument count
        \t - contract count: 1
        \t - argument count: 2
      MSG
    }

    it {
      klass = Class.new
      expect {
        klass.class_eval do
          contract String, String => nil
          def call(name:); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - contract count is not equal to argument count
        \t - contract count: 2
        \t - argument count: 1
      MSG
    }
  end
end
