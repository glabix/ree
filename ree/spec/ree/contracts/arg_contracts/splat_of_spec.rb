RSpec.describe Ree::Contracts::ArgContracts::SplatOf do
  context 'with valid contract' do
    it {
      expect(
        Class.new do
          contract SplatOf[Any] => :ok
          def call(*args)
            :ok
          end
        end.new.call(:ok)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract String, SplatOf[Symbol] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', :a, :b, :c)
      ).to eq ['ok', :a, :b, :c]
    }

    it {
      expect(
        Class.new do
          contract String, Integer, SplatOf[Symbol] => Any
          def call(a, b = 1, *args)
            [a, b] + args
          end
        end.new.call('ok', 1, :b, :c)
      ).to eq ['ok', 1, :b, :c]
    }

    it {
      expect(
        Class.new do
          contract String, Integer, SplatOf[Symbol] => Any
          def call(a, b = 1, *args)
            [a, b] + args
          end
        end.new.call('ok', 2, :a, :b, :c)
      ).to eq ['ok', 2, :a, :b, :c]
    }

    it {
      expect(
        Class.new do
          contract String, Integer, Symbol => Any
          def call(a, b = 1, c)
            [a, b, c]
          end
        end.new.call('ok', :a)
      ).to eq ['ok', 1, :a]
    }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract SplatOf[Any], SplatOf[Any] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Multiple SplatOf contracts are not allowed'
      )
    }

    it {
      expect {
        Class.new do
          contract Kwargs[test: true], SplatOf[Any] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'SplatOf contract should go before Kwargs'
      )
    }
  end
end
