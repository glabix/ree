# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class RangeOf
      extend Ree::Contracts::ArgContracts::Squarable
      include Ree::Contracts::Truncatable

      attr_reader :validator
      
      def initialize(*contracts)
        if contracts.size != 1
          raise BadContractError, 'RangeOf should accept exactly one contract'
        end

        @validator = Validators.fetch_for(contracts.first)
      end

      def valid?(value)
        value.is_a?(Range) &&
          validator.call(value.begin) &&
          validator.call(value.end)
      end

      def to_s
        "RangeOf[#{validator.to_s}]"
      end

      def message(value, name, lvl = 1)
        unless value.is_a?(Range)
          return "expected Range, got #{value.class} => #{truncate(value.inspect)}"
        end

        errors = []
        sps = "  " * lvl

        unless validator.call(value.begin)
          msg = validator.message(value.begin, "#{name}.begin", lvl + 1)
          errors << "\n\t#{sps} - #{name}.begin: #{msg}"
        end

        unless validator.call(value.end)
          msg = validator.message(value.end, "#{name}.end", lvl + 1)
          errors << "\n\t#{sps} - #{name}.end: #{msg}"
        end

        errors.join
      end
    end
  end
end
