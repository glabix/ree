RSpec.describe 'Ree::MethodDecorators disabling decorators' do
  class TestDecorator < Ree::MethodDecorators::Base
    def build_context
      puts "build_context for #{self.class.name}"
      nil
    end

    def before_decorate
      puts "before_decorate for #{self.class.name}"
    end

    def hook(receiver, args, kwargs, block, &method_call)
      puts "hook for #{self.class.name}"
      method_call.call
    end
  end

  TestDecorator2 = Class.new(TestDecorator)
  TestDecorator3 = Class.new(TestDecorator)

  context "with disabled decorators" do
    around do
      decorator_was_enabled = !Ree::MethodDecorators.no_method_decorators?
      Ree::MethodDecorators.disable_decorators
      _1.run
      Ree::MethodDecorators.enable_decorators if decorator_was_enabled
    end

    it "does not apply decorators" do
      expect {
        klass = Class.new do
          include Ree::MethodDecorators::Decoratable.with(
            test_decorator: TestDecorator,
          )

          test_decorator
          def call = nil
        end

        klass.new.call
      }.not_to output.to_stdout
    end
  end

  context "with whitelisted and blacklisted decorators" do
    around do
      decorator_was_disabled = Ree::MethodDecorators.no_method_decorators?
      Ree::MethodDecorators.enable_decorators
      Ree::MethodDecorators.enabled_decorators = [TestDecorator, TestDecorator3]
      Ree::MethodDecorators.disabled_decorators = [TestDecorator3]
      _1.run
      Ree::MethodDecorators.enabled_decorators = nil
      Ree::MethodDecorators.disabled_decorators = nil
      Ree::MethodDecorators.disable_decorators if decorator_was_disabled
    end

    it "applies only whitelisted and not blacklisted decorators" do
      expect {
        klass = Class.new do
          include Ree::MethodDecorators::Decoratable.with(
            test_decorator: TestDecorator,
            test_decorator2: TestDecorator2,
            test_decorator3: TestDecorator3,
          )

          test_decorator
          test_decorator2
          test_decorator3
          def call = nil
        end

        klass.new.call
      }.to output(
        "build_context for TestDecorator\n" \
        "before_decorate for TestDecorator\n" \
        "hook for TestDecorator\n"
      ).to_stdout
    end
  end
end
