# frozen_string_literal: true

module ReeDecorators
  class ClassValidator < BaseValidator
    def call(value)
      value.is_a?(contract)
    end

    def to_s
      contract.name
    end

    def message(value, _name, _lvl = 1)
      "expected #{contract}, got #{value.class} => #{truncate(value.inspect, 80)}"
    end
  end
end
