# frozen_string_literal: true

RSpec.describe Ree::MethodDecorators do
  class LogDecorator < Ree::MethodDecorators::Base
    require 'ostruct'

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

    def hook(receiver, args, kwargs, block, &method_call)
      puts "[#{context.level}] Calling #{method_name} with args: #{args.inspect}, kwargs: #{kwargs.inspect}"

      result = method_call.call(*args, **kwargs, &block)

      puts "[#{context.level}] #{method_name} returned: #{result.inspect}"

      result
    end
  end

  class MemoizeDecorator < Ree::MethodDecorators::Base
    def build_context
      OpenStruct.new(cache: {})
    end

    def hook(receiver, args, kwargs, block, &method_call)
      key = [receiver.object_id, args, kwargs]

      return context.cache[key] if context.cache.key?(key)

      result = method_call.call(*args, **kwargs, &block)
      context.cache[key] = result

      result
    end
  end

  class Calculator
    include Ree::MethodDecorators::Decoratable.with(
      alter_log: LogDecorator,
    )
    Ree::MethodDecorators::Decoratable.register(self, :log, LogDecorator)
    Ree::MethodDecorators::Decoratable.register(self, :memoize, MemoizeDecorator)

    alter_log :info
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
  end

  it "applies decorators to instance methods" do
    expect {
      Calculator.new.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "Performing expensive calculation\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "applies decorators to class methods" do
    expect {
      Calculator.class_calculate(1, 2, c: 3)
    }.to output(
      "[info] Calling class_calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "Performing expensive class calculation\n" \
      "[info] class_calculate returned: 6\n"
    ).to_stdout
  end

  it "properly orders decoration chain execution" do
    calculator = Calculator.new

    expect {
      calculator.calculate(1, 2, c: 3)
      calculator.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "Performing expensive calculation\n" \
      "[debug] calculate returned: 6\n" \
      "[debug] Calling calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "inherits decorated methods from parent classes" do
    class ChildCalculator < Calculator
    end

    expect {
      ChildCalculator.new.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "Performing expensive calculation\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "allows subclasses to define their own decorated methods" do
    class ChildCalculator < Calculator
      log :debug
      def addition(a, b, c: 0)
        puts "Performing addition operation"
        a + b + c
      end
    end

    expect {
      ChildCalculator.new.addition(1, 2, c: 3)
    }.to output(
      "[debug] Calling addition with args: [1, 2], kwargs: {c: 3}\n" \
      "Performing addition operation\n" \
      "[debug] addition returned: 6\n"
    ).to_stdout
  end

  describe "module methods decoration" do
    module CalculableModule
      include Ree::MethodDecorators::Decoratable.with(
        log: LogDecorator,
      )

      log :info
      def calculate_for_module(a, b, c: 0)
        puts "Performing module calculation"
        a + b + c
      end

      log :debug
      def self.module_function_calculate(a, b, c: 0)
        puts "Performing module function calculation"
        a + b + c
      end
    end

    class ClassIncludingModule
      include CalculableModule
    end

    it "applies decorators to methods defined in a module (when module is included)" do
      instance = ClassIncludingModule.new
      expect {
        instance.calculate_for_module(1, 2, c: 3)
      }.to output(
        "[info] Calling calculate_for_module with args: [1, 2], kwargs: {c: 3}\n" \
        "Performing module calculation\n" \
        "[info] calculate_for_module returned: 6\n"
      ).to_stdout
    end

    it "applies decorators to module functions (class methods on the module)" do
      expect {
        CalculableModule.module_function_calculate(1, 2, c: 3)
      }.to output(
        "[debug] Calling module_function_calculate with args: [1, 2], kwargs: {c: 3}\n" \
        "Performing module function calculation\n" \
        "[debug] module_function_calculate returned: 6\n"
      ).to_stdout
    end
  end
end
