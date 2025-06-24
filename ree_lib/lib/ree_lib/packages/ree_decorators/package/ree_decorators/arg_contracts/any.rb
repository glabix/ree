# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Any
      def self.valid?(_)
        true
      end

      def self.to_s
        "Any"
      end
    end
  end
end
