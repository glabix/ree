# frozen_string_literal: true

require_relative '../error'

module Ree::MethodDecorators
  # @api private
  #
  # Storage for method decorators during class/module definition phase.
  #
  # Temporarily stores decorator metadata until the corresponding method is defined.
  # After method definition and decorator application, the metadata is removed.
  #
  # @note This storage can cause memory leaks if a decorator was declared
  #   but no method was defined with it. This can happen with dynamically created
  #   or anonymous classes/modules. For normal usage with method definitions,
  #   cleanup happens automatically.
  class DefinitionStorage
    def self.storage
      @storage ||= {}
    end

    def self.storage_for(target)
      storage[target.object_id] ||= {}
    end

    def self.set(target, decorator_name, value)
      pending = storage_for(target)
      if pending.key?(decorator_name)
        raise Ree::Error.new(
          "Pending metadata for :#{decorator_name} already exists on #{target.inspect}",
          :invalid_dsl_usage
        )
      end
      pending[decorator_name] = value
    end

    def self.delete(target)
      storage.delete(target.object_id)&.values
    end
  end
end
