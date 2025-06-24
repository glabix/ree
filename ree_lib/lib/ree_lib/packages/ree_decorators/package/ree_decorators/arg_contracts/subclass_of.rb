# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class SubclassOf
      extend Squarable
      include Ree::LinkDSL

      link :truncate, from: :ree_string

      attr_reader :klass

      def initialize(klass)
        @klass = klass
      end

      def valid?(value)
        value.is_a?(Class) && value < klass
      end

      def to_s
        "SubclassOf[#{klass.inspect}]"
      end

      def message(value, name, lvl = 1)
        "expected #{truncate(self.to_s, 30)}, got #{truncate(value.inspect, 80)}"
      end
    end
  end
end
