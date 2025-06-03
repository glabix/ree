package_require("ree_decorators/dsl")

RSpec.describe 'ReeDecorators::DSL disabling decorators' do
  before :all do
    Ree.enable_irb_mode

    module ReeDecoratorsTest
      include Ree::PackageDSL

      package do
        depends_on :ree_decorators
      end

      class TestDecorator
        include ReeDecorators::DSL

        decorator :test_decorator

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

      class TestDecorator2 < TestDecorator
        decorator :test_decorator2
      end

      class TestDecorator3 < TestDecorator
        decorator :test_decorator3
      end
    end
  end

  after :all do
    Ree.disable_irb_mode
  end

  context "with disabled decorators" do
    around do
      decorator_was_enabled = !ReeDecorators.no_decorators?
      ReeDecorators.disable_decorators
      _1.run
      ReeDecorators.enable_decorators if decorator_was_enabled
    end

    it "does not apply decorators" do
      expect {
        class TestNoDecoratorsClass
          include Ree::LinkDSL

          link :test_decorator, from: :ree_decorators_test

          test_decorator
          def call = nil
        end

        TestNoDecoratorsClass.new.call
      }.not_to output.to_stdout
    end
  end

  context "with whitelisted and blacklisted decorators" do
    around do
      decorator_was_disabled = ReeDecorators.no_decorators?
      ReeDecorators.enable_decorators
      ReeDecorators.enabled_decorators = [ReeDecoratorsTest::TestDecorator, ReeDecoratorsTest::TestDecorator2]
      ReeDecorators.disabled_decorators = [ReeDecoratorsTest::TestDecorator, ReeDecoratorsTest::TestDecorator3]
      _1.run
      ReeDecorators.enabled_decorators = nil
      ReeDecorators.disabled_decorators = nil
      ReeDecorators.disable_decorators if decorator_was_disabled
    end

    it "applies only whitelisted and not blacklisted decorators" do
      expect {
        class TestWhitelistedDecoratorsClass
          include Ree::LinkDSL

          link :test_decorator, from: :ree_decorators_test
          link :test_decorator2, from: :ree_decorators_test
          link :test_decorator3, from: :ree_decorators_test

          test_decorator
          test_decorator2
          test_decorator3
          def call = nil
        end

        TestWhitelistedDecoratorsClass.new.call
      }.to output(
        "build_context for ReeDecoratorsTest::TestDecorator2\n" \
        "before_decorate for ReeDecoratorsTest::TestDecorator2\n" \
        "hook for ReeDecoratorsTest::TestDecorator2\n"
      ).to_stdout
    end
  end
end
