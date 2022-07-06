RSpec.describe 'Ree::Contracts instance and class methods' do
  subject(:klass) {
    Class.new do
      contract String => String
      def self.call(name); name; end

      contract Symbol => Symbol
      def call(name); name; end
    end
  }

  context 'with methods with same name' do
    it {
      expect(klass.call('class')).to eq 'class'
    }

    it {
      expect(klass.new.call(:instance)).to eq :instance
    }

    it {
      expect { klass.call(:class) }.to raise_error(Ree::Contracts::ContractError)
    }

    it {
      expect { klass.new.call('instance') }.to raise_error(Ree::Contracts::ContractError)
    }
  end
end
