RSpec.describe 'Ree::Contracts without args' do
  context 'with right contract' do
    subject(:obj) do
      Class.new do
        contract None => :ok
        def call
          :ok
        end
      end.new
    end

    it { expect(obj.call).to eq :ok }
  end

  context 'with short right contract' do
    subject(:obj) do
      Class.new do
        contract :ok
        def call
          :ok
        end
      end.new
    end

    it { expect(obj.call).to eq :ok }
  end

  context 'with old style no args contract' do
    it {
      expect {
        Class.new do
          contract nil => Symbol
          def call
            :ok
          end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'with many none contracts' do
    it {
      expect {
        Class.new do
          contract None, None => Symbol
          def call
            :ok
          end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'with none return contract' do
    it {
      expect {
        Class.new do
          contract None
          def call
          end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }
  end

  context 'with right return contract' do
    subject(:obj) do
      Class.new do
        contract Symbol
        def call
          :ok
        end
      end.new
    end

    it { expect(obj.call).to eq :ok }
  end

  context 'with wrong return contract' do
    subject(:obj) do
      Class.new do
        contract Integer
        def call
          :ok
        end
      end.new
    end

    it { expect { obj.call }.to raise_error(Ree::Contracts::ReturnContractError) }
  end
end
