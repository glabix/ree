# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Kwargs < SimpleDelegator
      extend Squarable

      attr_reader :contracts

      def self.to_s
        "Kwargs"
      end

      def initialize(**contracts)
        if contracts.empty?
          raise BadContractError, 'Kwargs contract should accept at least one contract'
        end

        @contracts = contracts
        super(contracts)
      end
    end
  end
end
