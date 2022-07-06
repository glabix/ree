RSpec.describe Ree::Contracts::ArgContracts::Any do
  subject(:obj) {
    Class.new do
      contract Any => Any
      def call(name)
        name
      end
    end.new
  }

  context 'with valid contract' do
    it { expect(obj.call(:ok)).to eq :ok }
  end
end
