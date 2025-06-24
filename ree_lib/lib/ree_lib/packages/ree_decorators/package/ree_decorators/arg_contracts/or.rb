# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Or
      extend Squarable
      include Ree::LinkDSL

      link :truncate, from: :ree_string

      attr_reader :validators

      def initialize(*contracts)
        @validators = contracts.map(&Validators.method(:fetch_for))
      end

      def to_s
        "Or[#{validators.map(&:to_s).join(', ')}]"
      end

      def valid?(value)
        validators.any? do |validator|
          validator.call(value)
        end
      end

      def message(value, name, lvl = 1)
        "expected #{truncate(to_s, 30)}, got #{truncate(value.inspect, 80)}"
      end
    end
  end
end
