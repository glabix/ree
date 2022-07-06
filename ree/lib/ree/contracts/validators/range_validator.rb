# frozen_string_literal: true

module Ree::Contracts
  class RangeValidator < BaseValidator
    def call(value)
      contract.include? value
    end

    def to_s
      contract.inspect
    end

    def message(value, _name, _lvl = 1)
      "expected value to be in range #{contract}, got #{truncate(value.inspect)}"
    end
  end
end
