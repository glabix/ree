# frozen_string_literal: true

module Ree::MethodDecorators
  # Storage for applied method decorators.
  #
  # Permanently stores decorator instances by their object_id.
  # Used during method calls to access decorator configuration and behavior.
  #
  # @example
  #   # Store decorator
  #   DecoratorStorage.set(MyClass, :my_method, decorator)
  #
  #   # Fetch decorator
  #   decorator = DecoratorStorage.fetch(
  #     DecoratorStorage.key(MyClass, :my_method, MyDecorator)
  #   )
  #
  # @note This storage can cause memory leaks. This can happen with dynamically created
  #   or anonymous classes/modules. If a class/module is garbage collected, its decorators
  #   will remain in memory until explicitly deleted.
  class DecoratorStorage
    def self.storage
      @storage ||= {}
    end

    def self.set(target, method_name, decorator)
      key = key(target, method_name, decorator.class)
      storage[key] = decorator
    end

    def self.fetch(key)
      storage.fetch(key)
    end

    def self.delete(key)
      storage.delete(key)
    end

    # Generates a unique key for storing/fetching decorator metadata
    # @param target [Class, Module] The target class/module
    # @param method_name [Symbol, String] The method name
    # @param decorator_class [Class] The decorator class
    # @return [String] A unique key for the decorator
    def self.key(target, method_name, decorator_class)
      "#{target.object_id}:#{method_name}:#{decorator_class.name}"
    end
  end
end
