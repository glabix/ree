# frozen_string_literal: true

module Ree::Contracts
  class ArrayValidator < BaseValidator
    attr_reader :validators

    def initialize(contract)
      super(contract)
      @validators = contract.map { |cont| Validators.fetch_for(cont) }
    end

    def to_s
      "[#{validators.map(&:to_s).join(', ')}]"
    end

    def call(value)
      return false unless value.is_a?(Array) && value.length == validators.length

      value.zip(validators).all? do |val, validator|
        validator.call(val)
      end
    end

    def message(value, name, lvl = 1)
      unless value.is_a?(Array)
        return "expected Array, got #{value.class} => #{truncate(value.inspect)}"
      end

      unless value.length == validators.length
        return "expected to have #{validators.length} #{pluralize(validators.length, 'item', 'items')}, got #{value.length} #{pluralize(value.length, 'item', 'items')} => #{truncate(value.inspect)}"
      end

      errors = []
      sps = "  " * lvl

      value.zip(validators).each_with_index do |(val, validator), idx|
        next if validator.call(val)

        msg = validator.message(val, "#{name}[#{idx}]", lvl + 1)
        errors << "\n\t#{sps} - #{name}[#{idx}]: #{msg}"

        if errors.size > 3
          errors << "\n\t#{sps} - ..."
          break
        end
      end

      errors.join
    end
  end
end
