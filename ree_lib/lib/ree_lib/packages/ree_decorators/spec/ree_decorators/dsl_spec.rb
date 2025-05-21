# frozen_string_literal: true

require 'ostruct'
package_require("ree_decorators/dsl")

RSpec.describe ReeDecorators::DSL do
  before do
    Ree.enable_irb_mode

    module ReeDecoratorsTest
      include Ree::PackageDSL

      package do
        depends_on :ree_decorators
      end

      class Log
        include ReeDecorators::DSL

        decorator :log do
        end

        def build_context(level = :info)
          OpenStruct.new(
            level: level,
            method_signature: nil
          )
        end

        def before_decorate
          method = if is_class_method
            target.method(method_name)
          else
            target.instance_method(method_name)
          end

          context.method_signature = {
            parameters: method.parameters,
            arity: method.arity,
          }
        end

        def hook(receiver, args, kwargs, blk, &method_call)
          puts "[#{context.level}] Calling #{method_name} with args: #{args.inspect}, kwargs: #{kwargs.values.inspect}"

          result = method_call.call(args, kwargs, blk)

          puts "[#{context.level}] #{method_name} returned: #{result.inspect}"

          result
        end
      end

      class Memoize
        include ReeDecorators::DSL

        decorator :memoize do
        end

        def build_context
          OpenStruct.new(cache: {})
        end

        def hook(receiver, args, kwargs, block, &method_call)
          key = [receiver.object_id, args, kwargs]

          return context.cache[key] if context.cache.key?(key)

          result = method_call.call(args, kwargs, block)
          context.cache[key] = result

          result
        end
      end

      class Doc
        include ReeDecorators::DSL

        decorator :doc

        def build_context(doc)
          OpenStruct.new(doc: doc)
        end
      end

      class Calculator
        include Ree::BeanDSL

        bean :calculator do
          link :log, from: :ree_decorators_test
          link :memoize, from: :ree_decorators_test
        end

        log :info
        def self.class_calculate(a, b, c: 0)
          puts "Performing expensive class calculation"
          a + b + c
        end

        log :debug
        memoize
        def calculate(a, b, c: 0)
          puts "Performing expensive calculation"
          a + b + c
        end

        doc "Do nothing"
        def do_nothing(name) = "Hello from do_nothing #{name}"
      end
    end

    Ree.disable_irb_mode
  end

  it "applies decorators to instance methods" do
    expect {
      ReeDecoratorsTest::Calculator.new.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: [3]\n" \
      "Performing expensive calculation\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "applies decorators to class methods" do
    expect {
      ReeDecoratorsTest::Calculator.class_calculate(1, 2, c: 3)
    }.to output(
      "[info] Calling class_calculate with args: [1, 2], kwargs: [3]\n" \
      "Performing expensive class calculation\n" \
      "[info] class_calculate returned: 6\n"
    ).to_stdout
  end

  it "properly orders decoration chain execution" do
    calculator = ReeDecoratorsTest::Calculator.new

    expect {
      calculator.calculate(1, 2, c: 3)
      calculator.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: [3]\n" \
      "Performing expensive calculation\n" \
      "[debug] calculate returned: 6\n" \
      "[debug] Calling calculate with args: [1, 2], kwargs: [3]\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "inherits decorated methods from parent classes" do
    class ChildCalculator < ReeDecoratorsTest::Calculator
    end

    expect {
      ChildCalculator.new.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: [3]\n" \
      "Performing expensive calculation\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "allows subclasses to define their own decorated methods" do
    class ChildCalculator < ReeDecoratorsTest::Calculator
      log :debug
      def addition(a, b, c: 0)
        puts "Performing addition operation"
        a + b + c
      end
    end

    expect {
      ChildCalculator.new.addition(1, 2, c: 3)
    }.to output(
      "[debug] Calling addition with args: [1, 2], kwargs: [3]\n" \
      "Performing addition operation\n" \
      "[debug] addition returned: 6\n"
    ).to_stdout
  end

  it "decorates methods without hook" do
    expect(ReeDecoratorsTest::Calculator.new.do_nothing("John")).to eq("Hello from do_nothing John")
  end

  it "works only on named classes" do
    expect {
      Class.new do
        include ReeDecorators::DSL

        decorator :test
      end
    }.to raise_error(ArgumentError, "ReeDecorators::DSL does not support anonymous classes")

    expect {
      Module.new do
        include ReeDecorators::DSL

        decorator :test
      end
    }.to raise_error(ArgumentError, "ReeDecorators::DSL should be included to named classed only")
  end
end
