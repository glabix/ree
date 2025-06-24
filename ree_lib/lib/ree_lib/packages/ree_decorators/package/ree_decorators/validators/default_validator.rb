# frozen_string_literal: true

module ReeDecorators
  class DefaultValidator < BaseValidator
    def call(value)
      contract == value
    end

    def to_s
      truncate(
        contract.respond_to?(:to_s) ? contract.to_s : contract.inspect,
        10
      )
    end

    def message(value, _name, _lvl = 1)
      "expected #{truncate(contract.inspect, 40)}, got #{truncate(value.inspect, 40)}"
    end
  end
end
