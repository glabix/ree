RSpec.describe Ree::Contracts::ArgContracts::Splat do
  context 'with valid contract' do
    it {
      expect(
        Class.new do
          contract String, Splat[SplatOf[Symbol]] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', :a, :b, :c)
      ).to eq ['ok', :a, :b, :c]
    }

    it {
      expect(
        Class.new do
          contract String, Splat[String, SplatOf[Symbol]] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', 'a', :b, :c)
      ).to eq ['ok', 'a', :b, :c]
    }

    it {
      expect(
        Class.new do
          contract String, Splat[SplatOf[Symbol], String, String] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', :a, 'b', 'c')
      ).to eq ['ok', :a, 'b', 'c']
    }

    it {
      expect(
        Class.new do
          contract String, Splat[Symbol, SplatOf[String], Integer] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', :a, 'b', 'c', 1)
      ).to eq ['ok', :a, 'b', 'c', 1]
    }

    it {
      expect(
        Class.new do
          contract String, Splat[{test: Bool}, SplatOf[String], ArrayOf[String]] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', {test: true}, 'b', 'c', ['s'])
      ).to eq ['ok', {test: true}, 'b', 'c', ['s']]
    }

    it {
      expect(
        Class.new do
          contract String, Splat[SplatOf[Any]] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', :a)
      ).to eq ['ok', :a]
    }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract String, Splat[SplatOf[String], String, SplatOf[String]] => Any
          def call(a, *args)
            [a] + args
          end
        end.new.call('ok', :a, :b, :c)
      }.to raise_error(Ree::Contracts::BadContractError, 'Splat contract should include one SplatOf contract')
    }

    it {
      expect {
        Class.new do
          contract Splat[SplatOf[Any]], Splat[SplatOf[Any]] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Multiple Splat contracts are not allowed'
      )
    }

    it {
      expect {
        Class.new do
          contract Kwargs[test: true], Splat[SplatOf[Any]] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Splat contract should go before Kwargs'
      )
    }

    it {
      expect {
        Class.new do
          contract Ksplat[test: Any], Splat[SplatOf[Any]] => :ok
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Splat contract should go before Ksplat'
      )
    }

    it {
      obj = Class.new do
        contract String, Splat[SplatOf[String]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', '1', 2)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[0..1]: \n\t     - args[0..1][1]: expected String, got Integer => 2")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[String]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[0]: expected String, got Integer => 1")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[String]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', '1', 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[1..1]: \n\t     - args[1..1][0]: expected String, got Integer => 1")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[SplatOf[String], String] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[1]: expected String, got Integer => 1")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[SplatOf[String], String] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', '1', 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[1]: expected String, got Integer => 1")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[SplatOf[Symbol]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 1, 2)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[0..1]: \n\t     - args[0..1][0]: expected Symbol, got Integer => 1\n\t     - args[0..1][1]: expected Symbol, got Integer => 2")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[SplatOf[Symbol], String] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', :a, :s)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[1]: expected String, got Symbol => :s")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[Symbol]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', :a, :s)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[0]: expected String, got Symbol => :a")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[Symbol]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 'a', 's')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[1..1]: \n\t     - args[1..1][0]: expected Symbol, got String => \"s\"")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, String, SplatOf[Symbol]] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 'a')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args: expected at least 2 values for Splat[String, String, SplatOf[Symbol]], got 1 value => [\"a\"]")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[Symbol], Integer] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', :a, :b, :c, 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[0]: expected String, got Symbol => :a")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[Symbol], Integer] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 'a', :b, 'c', 1)
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[1..2]: \n\t     - args[1..2][1]: expected Symbol, got String => \"c\"")
      }
    }

    it {
      obj = Class.new do
        contract String, Splat[String, SplatOf[Symbol], Integer] => Any
        def call(a, *args)
          [a] + args
        end
      end

      expect {
        obj.new.call('ok', 'a', :b, :c, 'd')
      }.to raise_error(Ree::Contracts::ContractError) { |e|
        expect(e.message).to eq("Contract violation for #{obj}#call\n\t - args:\n\t   - args[3]: expected Integer, got String => \"d\"")
      }
    }
  end
end
