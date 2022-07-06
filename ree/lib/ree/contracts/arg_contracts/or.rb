# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Or
      extend Ree::Contracts::ArgContracts::Squarable
      include Ree::Contracts::Truncatable

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
        "expected #{truncate(self.to_s, 30)}, got #{truncate(value.inspect)}"
      end
    end
  end
end
