# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Eq
      extend Squarable
      include Ree::LinkDSL

      link :truncate, from: :ree_string

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
        "expected #{truncate(to_s, 30)}, got #{truncate(value.inspect, 80)}"
      end
    end
  end
end
