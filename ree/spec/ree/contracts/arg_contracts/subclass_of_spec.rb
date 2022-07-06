RSpec.describe Ree::Contracts::ArgContracts::SubclassOf do
  class TestStringForSubclassOf < String; end

  subject(:obj) {
    Class.new do
      contract SubclassOf[String] => Any
      def call(val)
        val
      end
    end.new
  }

  context 'with valid contract' do
    it {
      expect(obj.call(TestStringForSubclassOf)).to eq(TestStringForSubclassOf)
    }
  end

  context 'with invalid contract' do
    it {
      expect { obj.call(String) }.to raise_error(
        Ree::Contracts::ContractError,
        "Contract violation for #{obj.class}#call\n\t - val: expected SubclassOf[String], got String"
      )
    }

    it {
      expect { obj.call(Object) }.to raise_error(
        Ree::Contracts::ContractError,
        "Contract violation for #{obj.class}#call\n\t - val: expected SubclassOf[String], got Object"
      )
    }

    it {
      obj_arg = Object.new
      expect { obj.call(obj_arg) }.to raise_error(
        Ree::Contracts::ContractError,
        "Contract violation for #{obj.class}#call\n\t - val: expected SubclassOf[String], got #{obj_arg.inspect}"
      )
    }
  end
end
