RSpec.describe 'Ree::Contracts optional kwargs' do
  subject(:obj) {
    Class.new do
      contract Kwargs[sym: Symbol, str: String] => [Symbol, String]
      def call(sym:, str: 'str')
        [sym, str]
      end

      contract Kwargs[sym: Symbol], Ksplat[RestKeys => Any] => [Symbol, Hash]
      def call_with_splat(sym: :sym, **splat)
        [sym, splat]
      end
    end.new
  }

  context 'with right contract' do
    it { expect(obj.call(sym: :sym)).to eq [:sym, 'str'] }

    it { expect(obj.call(sym: :sym, str: 'str')).to eq [:sym, 'str'] }

    it { expect(obj.call(str: 'str', sym: :sym)).to eq [:sym, 'str'] }

    it { expect(obj.call_with_splat(splat: :splat)).to eq [:sym, { splat: :splat }] }

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
      expect { obj.call(sym: :sym, missing: 'missing') }.to raise_error(
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
          contract String, String => nil
          def call(name:, opt: :opt); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - methods with optional keyword arguments should use Kwargs[...] to describe all keyword args
      MSG
    }

    it {
      expect {
        Class.new do
          contract String, Kwargs[opt: String] => nil
          def call(name:, opt: :opt); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end
end
