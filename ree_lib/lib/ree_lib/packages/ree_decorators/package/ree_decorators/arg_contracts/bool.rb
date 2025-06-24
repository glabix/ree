# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Bool
      include Ree::LinkDSL

      link :truncate, from: :ree_string, target: :class

      def self.valid?(value)
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end

      def self.message(value, name, lvl = 1)
        "expected Bool, got #{value.class} => #{truncate(value.inspect, 80)}"
      end

      def self.to_s
        "Bool"
      end
    end
  end
end
