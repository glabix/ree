# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Exactly
      extend Squarable
      include Ree::LinkDSL

      link :truncate, from: :ree_string

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
        "expected #{truncate(to_s, 30)}, got #{truncate(value.class.inspect, 80)}"
      end
    end
  end
end
