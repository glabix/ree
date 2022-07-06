# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Eq
      extend Ree::Contracts::ArgContracts::Squarable
      include Ree::Contracts::Truncatable

      attr_reader :contract
      
      def initialize(contract)
        @contract = contract
      end

      def valid?(value)
        value.equal?(contract)
      end

      def to_s
        "Eq[#{contract.inspect}]"
      end

      def message(value, name, lvl = 1)
        "expected #{truncate(self.to_s, 30)}, got #{truncate(value.inspect)}"
      end
    end
  end
end
