# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Any
      def self.valid?(value)
        true
      end

      def self.to_s
        "Any"
      end
    end
  end
end
