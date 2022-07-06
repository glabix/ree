RSpec.describe Ree::Contracts do
  subject(:klass) {
    Class.new do
      doc("call method")
      contract(Integer => Symbol).throws(RuntimeError)
      def self.call(name)
        :ok
      end

      contract(String => Symbol).throws(StandardError, RuntimeError)
      def call(name)
        :ok
      end
    end
  }

  it {
    expect(Ree::Contracts.get_method_decorator(klass, :call, scope: :instance))
      .to be_a(Ree::Contracts::MethodDecorator)
  }

  it {
    expect(Ree::Contracts.get_method_decorator(klass, :call, scope: :class))
      .to be_a(Ree::Contracts::MethodDecorator)
  }
end
