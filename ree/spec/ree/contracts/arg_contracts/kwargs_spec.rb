RSpec.describe Ree::Contracts::ArgContracts::Kwargs do
  context 'with valid contract' do
    it {
      expect(
        Class.new do
          contract Kwargs[key: Symbol] => :ok
          def call(key:)
            :ok
          end
        end.new.call(key: :ok)
      ).to eq :ok
    }

    it {
      expect(
        Class.new do
          contract Kwargs[key: Symbol] => :ok
          def call(key:)
            :ok
          end
        end.new.call(key: :ok)
      ).to eq :ok
    }
  end

  context 'with bad contract' do
    it {
      expect {
        Class.new do
          contract Kwargs[] => :ok
          def call(); end
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Kwargs contract should accept at least one contract'
      )
    }

    it {
      expect {
        Class.new do
          contract None => Kwargs[status: :ok]
          def call(); end
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat'
      )
    }

    it {
      expect {
        Class.new do
          contract Kwargs[k: String], Kwargs[v: String] => :ok
          def call(); end
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Only one Kwargs contract could be provided'
      )
    }

    it {
      expect {
        Class.new do
          contract Kwargs[k: String], String => :ok
          def call(a, k:); end
        end
      }.to raise_error(
        Ree::Contracts::BadContractError,
        'Kwargs contract should appear in the end'
      )
    }
  end
end
