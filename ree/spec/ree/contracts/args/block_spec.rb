RSpec.describe 'Ree::Contracts block arg' do
  context 'when block is not last contract' do
    it {
      expect {
        Class.new do
          contract Block, String => nil
          def call(*); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'when block is not last contract' do
    it {
      expect {
        Class.new do
          contract Optblock, String => nil
          def call(*); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'with many block contracts' do
    it {
      expect {
        Class.new do
          contract Block, Block => nil
          def call(*); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'with many block contracts' do
    it {
      expect {
        Class.new do
          contract Optblock, Block => nil
          def call(*); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'when return contract is block contract' do
    it {
      expect {
        Class.new do
          contract String => Block
          def call(*); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'when return contract is block contract' do
    it {
      expect {
        Class.new do
          contract String => Optblock
          def call(*); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'when there is no block contract for a block' do
    it {
      klass = Class.new
      expect {
        klass.class_eval do
          contract String => nil
          def call(name, &blk); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - contract count is not equal to argument count
        \t - contract count: 1
        \t - argument count: 2
      MSG
    }
  end
end
