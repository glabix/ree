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

  class Calculator
    # include Ree::MethodDecorators::Decoratable.with(log: LogDecorator)

    include Ree::MethodDecorators::Decoratable
    LogDecorator.register(self, :log)

    log :info
    def self.class_calculate(a, b, c: 0)
      a + b + c
    end

    log :debug
    def calculate(a, b, c: 0)
      a + b + c
    end
  end

  it "logs method calls with captured signature" do
    expect {
      Calculator.new.calculate(1, 2, c: 3)
    }.to output(
      "[debug] Calling calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "[debug] calculate returned: 6\n"
    ).to_stdout
  end

  it "logs class method calls with captured signature" do
    expect {
      Calculator.class_calculate(1, 2, c: 3)
    }.to output(
      "[info] Calling class_calculate with args: [1, 2], kwargs: {c: 3}\n" \
      "[info] class_calculate returned: 6\n"
    ).to_stdout
  end
end
