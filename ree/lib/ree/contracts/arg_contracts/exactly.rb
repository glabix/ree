# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Exactly
      extend Ree::Contracts::ArgContracts::Squarable
      include Ree::Contracts::Truncatable

      attr_reader :klass
      
      def initialize(klass)
        @klass = klass
      end

      def valid?(value)
        value.class == klass
      end

      def to_s
        "Exactly[#{klass.inspect}]"
      end

      def message(value, name, lvl = 1)
        "expected #{truncate(self.to_s, 30)}, got #{truncate(value.class.inspect)}"
      end
    end
  end
end
