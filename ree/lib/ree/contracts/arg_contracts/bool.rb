# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Bool
      extend Ree::Contracts::Truncatable

      def self.valid?(value)
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end

      def self.message(value, name, lvl = 1)
        "expected Bool, got #{value.class} => #{truncate(value.inspect)}"
      end

      def self.to_s
        "Bool"
      end
    end
  end
end
