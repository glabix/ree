# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class HashOf
      extend Ree::Contracts::ArgContracts::Squarable
      include Ree::Contracts::Truncatable

      attr_reader :key_validator, :value_validator
      
      def initialize(*contracts)
        if contracts.size != 2
          raise BadContractError, 'HashOf should accept exactly two contracts'
        end

        @key_validator   = Validators.fetch_for(contracts[0])
        @value_validator = Validators.fetch_for(contracts[1])
      end

      def valid?(value)
        value.is_a?(Hash) &&
          value.each_key.all?(&key_validator.method(:call)) &&
          value.each_value.all?(&value_validator.method(:call))
      end

      def to_s
        "HashOf[#{key_validator.to_s}, #{value_validator.to_s}]"
      end

      def message(value, name, lvl = 1)
        unless value.is_a?(Hash)
          return "expected Hash, got #{value.class} => #{truncate(value.inspect)}"
        end

        errors = []
        sps = "  " * lvl

        value.each do |key, val|
          if errors.size > 4
            errors << "\n\t#{sps} - ..."
            break
          end

          unless key_validator.call(key)
            msg = key_validator.message(key, "#{name}[#{key.inspect}]", lvl + 1)
            errors << "\n\t#{sps} - invalid key #{key.inspect}, #{msg}"
          end

          unless value_validator.call(val)
            msg = key_validator.message(val, "#{name}[#{key.inspect}]", lvl + 1)
            errors << "\n\t#{sps} - invalid value for #{key.inspect} key, #{msg}"
          end
        end

        errors.join
      end
    end
  end
end
