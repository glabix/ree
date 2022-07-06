# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class SplatOf
      include Ree::Contracts::Truncatable
      
      attr_reader :validator
      
      class << self
        def [](contract)
          new(contract)
        end
      end

      def initialize(contract)
        forbidden_class_contracts = Ree::Contracts::Validators::FORBIDDEN_CONTRACTS

        contract_name = if forbidden_class_contracts.include?(contract)
          contract.to_s
        elsif forbidden_class_contracts.include?(contract.class)
          contract.class.to_s
        end

        if contract_name
          raise BadContractError, "#{contract_name} contract is not allowed to use inside SplatOf contract"
        end

        @validator = Validators.fetch_for(contract)
      end

      def valid?(value)
        value.is_a?(Array) && value.all?(&validator.method(:call))
      end

      def to_s
        "SplatOf[#{validator.to_s}]"
      end

      def message(value, name, lvl = 1)
        unless value.is_a?(Array)
          return "expected #{to_s}, got #{value.class} => #{truncate(value.inspect)}"
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
