RSpec.describe 'Ree::Contracts throws' do
  context 'with right contract' do
    it {
      expect(
        Class.new do
          contract(Symbol).throws(StandardError, ArgumentError)
          def call
            :ok
          end
        end.new.call
      ).to eq :ok
    }
  end
end
