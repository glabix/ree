RSpec.describe 'Ree::Contracts#contract' do
  context 'with bad contract' do
    context 'Kwargs' do
      it {
        expect {
          Class.new do
            contract Any => Kwargs[test: Symbol]
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat')
        end

        expect {
          Class.new do
            contract Any => Kwargs
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat')
        end

        expect {
          Class.new do
            contract Kwargs[test: Symbol], Any => nil
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Kwargs contract should appear in the end')
        end
      }
    end

    context 'None' do
      it {
        expect {
          Class.new do
            contract None, Any => nil
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Combination of None contract with other contracts is not allowed')
        end
      }

      it {
        expect {
          Class.new do
            contract None => None
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat')
        end
      }

      it {
        expect {
          Class.new do
            contract None => Kwargs
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat')
        end
      }

      it {
        expect {
          Class.new do
            contract ArrayOf[None] => nil
          end
        }.to raise_error(Ree::Error) do |e|
          expect(e.message).to eq('None is not supported arg validator')
        end
      }

      it {
        expect {
          Class.new do
            contract ArrayOf[Kwargs] => nil
          end
        }.to raise_error(Ree::Error) do |e|
          expect(e.message).to eq('Kwargs is not supported arg validator')
        end
      }

      it {
        expect {
          Class.new do
            contract ArrayOf[Block] => nil
          end
        }.to raise_error(Ree::Error) do |e|
          expect(e.message).to eq('Block is not supported arg validator')
        end
      }

      it {
        expect {
          Class.new do
            contract ArrayOf[Optblock] => nil
          end
        }.to raise_error(Ree::Error) do |e|
          expect(e.message).to eq('Optblock is not supported arg validator')
        end
      }
    end

    context 'Block (Optblock)' do
      it {
        expect {
          Class.new do
            contract Block, Any => nil
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Block (Optblock) contract should appear in the end')
        end

        expect {
          Class.new do
            contract Optblock, Any => nil
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Block (Optblock) contract should appear in the end')
        end

        expect {
          Class.new do
            contract None => Block
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat')
        end

        expect {
          Class.new do
            contract None => Optblock
          end
        }.to raise_error(Ree::Contracts::BadContractError) do |e|
          expect(e.message).to eq('Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat')
        end
      }
    end
    
    context "missing return value" do
      it {
        expect {
          Class.new do
            contract Integer, Integer
          end
        }.to raise_error(Ree::Contracts::BadContractError)
      }
    end

    context "missing contract" do
      it {
        expect {
          Class.new do
            contract
          end
        }.to raise_error(Ree::Contracts::BadContractError)
      }
    end
  end

  context 'when contract already defined' do
    it {
      expect {
        Class.new do
          contract String => nil
          contract String => nil
        end
      }.to raise_error(Ree::Error) do |e|
        expect(e.message).to eq("Another active contract definition found")
      end
    }
  end
end
