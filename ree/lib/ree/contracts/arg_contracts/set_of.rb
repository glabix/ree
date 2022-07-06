# frozen_string_literal: true

require 'set'

module Ree::Contracts
  module ArgContracts
    class SetOf
      extend Ree::Contracts::ArgContracts::Squarable
      include Ree::Contracts::Truncatable

      attr_reader :validator
      
      def initialize(*contracts)
        if contracts.size != 1
          raise BadContractError, 'SetOf should accept exactly one contract'
        end

        @validator = Validators.fetch_for(contracts.first)
      end

      def valid?(value)
        value.is_a?(Set) &&
          value.all?(&validator.method(:call))
      end

      def to_s
        "SetOf[#{validator.to_s}]"
      end

      def message(value, name, lvl = 1)
        unless value.is_a?(Set)
          return "expected Set, got #{value.class} => #{truncate(value.inspect)}"
        end

        errors = []
        sps = "  " * lvl

        value.each_with_index do |val, idx|
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
end
