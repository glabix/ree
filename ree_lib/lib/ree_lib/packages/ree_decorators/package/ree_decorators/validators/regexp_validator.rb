# frozen_string_literal: true

module ReeDecorators
  class RegexpValidator < BaseValidator
    def call(value)
      value =~ contract
    end

    def to_s
      contract.to_s
    end

    def message(value, name, lvl = 1)
      "expected to match #{contract.to_s}, got #{truncate(value.inspect, 80)}"
    end
  end
end
