# frozen_string_literal: true

module Ree::MethodDecorators
  # Base class for all method decorators.
  #
  # To create your own decorator, subclass this and override `build_context`, `before_decorate` and/or `hook`.
  #
  # @example
  #   class MyDecorator < Ree::MethodDecorators::Base
  #     def build_context(some_metadata)
  #       # Build a context object for this decorator
  #       # Permit attributes from the decorator declaration
  #       OpenStruct.new(
  #         some_metadata: some_metadata
  #       )
  #     end
  #
  #     def before_decorate
  #       # Optional: called before the method is redefined
  #       # Access meta via self.method_name, self.target, etc.
  #     end
  #
  #     def hook(receiver, args, kwargs, block, &method_call)
  #       # Do something before
  #       result = method_call.call(*args, **kwargs, &block)
  #       # Do something after
  #       result
  #     end
  #   end
  class Base
    # The context for this decorator
    attr_reader :context

    # The name of the method being decorated (Symbol)
    attr_accessor :method_name

    # True if this is a class method, false if instance method
    attr_accessor :is_class_method

    # The class or module that owns the decorated method
    attr_accessor :target

    def initialize(...)
      @context = build_context(...)
    end

    # Override to provide a custom context object
    def build_context
      nil
    end

    # Called before the method is redefined.
    # Override in your decorator if you need to do setup.
    # All meta (method_name, is_class_method, target, context) is available as attributes.
    # def before_decorate
    #   no-op by default
    # end

    # Called when the decorated method is invoked.
    # Override in your decorator to add behavior.
    #
    # @param receiver [Object] the object the method is called on
    # @param args [Array, nil] positional arguments
    # @param kwargs [Hash, nil] keyword arguments
    # @param block [Proc, nil] the block passed to the method
    # @yield the next decorator or the original method
    # @return [Object] the result of the method call
    # def hook(receiver, args, kwargs, block, &original_method_call)
    #   do something before
    #   result = original_method_call.call(*args, **kwargs, &block)
    #   do something after
    #   result
    # end

    # Freezes the context and the decorator itself
    def freeze
      context.freeze
      super
    end
  end
end
