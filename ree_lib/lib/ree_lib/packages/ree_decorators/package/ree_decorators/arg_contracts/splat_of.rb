# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class SplatOf
      extend Squarable
      include Ree::LinkDSL

      link :truncate, from: :ree_string

      attr_reader :validator

      def self.to_s
        "SplatOf"
      end

      def initialize(*contracts)
        if contracts.size != 1
          raise BadContractError, 'SplatOf should accept exactly one contract'
        end

        contract = contracts.first

        forbidden_contract_name = if Validators::FORBIDDEN_CONTRACTS.include?(contract)
          contract.to_s
        elsif Validators::FORBIDDEN_CONTRACTS.include?(contract.class)
          contract.class.to_s
        end

        if forbidden_contract_name
          raise BadContractError, "#{forbidden_contract_name} contract is not allowed to use inside SplatOf contract"
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
          return "expected #{to_s}, got #{value.class} => #{truncate(value.inspect, 80)}"
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
