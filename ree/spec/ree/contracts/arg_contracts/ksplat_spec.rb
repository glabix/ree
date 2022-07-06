RSpec.describe Ree::Contracts::ArgContracts::Ksplat do
  context 'with valid contract' do
    it {
      expect(
        Class.new do
          contract Ksplat[test: Any, RestKeys => Any] => :ok
          def call(**args)
            :ok
          end
        end.new.call(test: :ok)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract Ksplat[a: Integer, b?: Symbol, RestKeys => Any] => :ok
          def call(**args)
            :ok
          end
        end.new.call(a: 1, b: :ok)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract Ksplat[a: Integer, b?: Any, RestKeys => Any] => :ok
          def call(**args)
            :ok
          end
        end.new.call(a: 1)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract Ksplat[a: Integer, b?: Any, RestKeys => Symbol] => :ok
          def call(**args)
            :ok
          end
        end.new.call(a: 1, e: :ok)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract String, Integer, SplatOf[String], Kwargs[c: Bool, d: Symbol], Ksplat[e: Integer, f?: Any, RestKeys => Symbol] => :ok
          def call(a, b = 1, *args, c:, d: :ok, **kwargs)
            :ok
          end
        end.new.call('a', 1, 'args', c: true, d: :ok, e: 1, f: Object.new, g: :ok)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract String, Integer, SplatOf[String], Kwargs[c: Bool, d: Symbol], Ksplat[e: Integer, f?: Any, RestKeys => Symbol] => :ok
          def call(a, b = 1, *args, c:, d: :ok, **kwargs)
            :ok
          end
        end.new.call('a', c: true, e: 1)
      ).to eq :ok
    }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract Ksplat[test: Any], Ksplat[test: Any] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Multiple Ksplat contracts are not allowed'
      )
    }

    it {
      expect {
        Class.new do
          contract Kwargs[test: Any], Ksplat[test: Any] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Ksplat & Kwargs contracts has same keys [:test]'
      )
    }

    it {
      expect {
        Class.new do
          contract Ksplat[test: Any], Kwargs[test1: Any] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Ksplat contract should go after Kwargs'
      )
    }

    it {
      obj = Class.new do
        contract Ksplat[a: Integer, b?: Any, RestKeys => Any] => :ok
        def call(**args)
          :ok
        end
      end

      expect {
        obj.new.call(a: 's')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[:a]: expected Integer, got String => \"s\"")
      }
    }

    it {
      obj = Class.new do
        contract Ksplat[a: Integer, b?: Symbol, RestKeys => Any] => :ok
        def call(**args)
          :ok
        end
      end

      expect {
        obj.new.call(a: 1, b: 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[:b]: expected Symbol, got Integer => 1")
      }
    }

    it {
      obj = Class.new do
        contract Ksplat[a: Integer, b?: Symbol, RestKeys => Integer] => :ok
        def call(**args)
          :ok
        end
      end

      expect {
        obj.new.call(a: 1, b: :ok, c: 's')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[:c]: expected Integer, got String => \"s\"")
      }
    }

    it {
      obj = Class.new do
        contract Ksplat[a: Integer, b?: Symbol] => :ok
        def call(**args)
          :ok
        end
      end

      expect {
        obj.new.call(a: 1, c: 's')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[:c]: unexpected")
      }
    }

    it {
      obj = Class.new do
        contract Ksplat[RestKeys => Integer] => :ok
        def call(**args)
          :ok
        end
      end

      expect {
        obj.new.call(a: 's')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[:a]: expected Integer, got String => \"s\"")
      }
    }

    it {
      obj = Class.new do
        contract Ksplat[RestKeys => Integer] => :ok
        def call(**args)
          :ok
        end
      end

      expect {
        obj.new.call(RestKeys => 's')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args: RestKeys is a reserved key for Ksplat contract")
      }
    }
  end
end
