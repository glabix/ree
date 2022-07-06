# frozen_string_literal: true

module Ree::Contracts
  class ValidValidator < BaseValidator
    def call(value)
      contract.valid? value
    end

    def to_s
      if contract.respond_to?(:to_s)
        contract.to_s
      else
        klass = contract.is_a?(Class) ? contract : contract.class
        klass.name
      end
    end

    def message(value, name, lvl = 1)
      if contract.respond_to?(:message)
        contract.message(value, name, lvl)
      else
        obj_name = contract.is_a?(Class) ? contract : contract.class
        op = contract.is_a?(Class) ? '.' : '#'
        "#{obj_name}#{op}valid? failed for #{truncate(value.inspect)}"
      end
    end
  end
end
