# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Kwargs < SimpleDelegator
      def self.[](**contracts)
        if contracts.empty?
          raise BadContractError, 'Kwargs contract should accept at least one contract'
        end

        new(**contracts)
      end

      attr_reader :contracts
      
      def initialize(**contracts)
        @contracts = contracts
        super(contracts)
      end
    end
  end
end
