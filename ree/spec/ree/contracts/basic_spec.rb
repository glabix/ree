RSpec.describe Ree::Contracts do
  subject(:obj) do
    Class.new do
      contract String => 'ok'
      def call(name)
        name.to_s
      end

      private

      contract String => String
      def private_call(name)
        name.to_s
      end
    end.new
  end

  context 'method privacy' do
    it { expect(obj.class.public_instance_methods.include?(:call)).to eq (true) }
    it { expect(obj.class.private_instance_methods.include?(:private_call)).to eq (true) }
  end

  context 'with right contract' do
    it { expect(obj.call('ok')).to eq 'ok' }
  end

  context 'with insufficient arguments' do
    it {
      expect { obj.call }.to raise_error(
        Ree::Contracts::ContractError,
        "Wrong number of arguments for #{obj.class}#call\n\t - missing value for `name`"
      )
    }
  end

  context 'with violated args contract' do
    it {
      expect { obj.call(:ok) }.to raise_error(Ree::Contracts::ContractError)
    }
  end

  context 'with violated return contract' do
    it { expect { obj.call('error') }.to raise_error(Ree::Contracts::ReturnContractError) }
  end

  context 'with insufficient contracts' do
    it {
      klass = Class.new
      expect {
        klass.class_eval do
          contract String => nil
          def call(a, b, k1:); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - contract count is not equal to argument count
        \t - contract count: 1
        \t - argument count: 3
      MSG
    }

    it {
      expect {
        Class.new do
          contract String => nil
          def method(a, b = nil); end
        end
      }.to raise_error(Ree::Contracts::BadContractError)
    }

    it {
      klass = Class.new
      expect {
        klass.class_eval do
          contract String, String, Kwargs[k1: String] => nil
          def call(a, k1:); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - contract count is not equal to argument count
        \t - contract count: 3
        \t - argument count: 2
      MSG
    }

    it {
      klass = Class.new
      expect {
        klass.class_eval do
          contract String, String, String => nil
          def call(arg, name:); end
        end
      }.to raise_error(Ree::Contracts::BadContractError, <<~MSG.chomp)
        Contract definition mismatches method definition for #{klass}#call
        \t - contract count is not equal to argument count
        \t - contract count: 3
        \t - argument count: 2
      MSG
    }
  end
end
