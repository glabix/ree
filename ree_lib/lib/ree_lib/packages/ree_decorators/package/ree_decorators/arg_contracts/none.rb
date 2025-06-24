# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class None
      def self.valid?(_)
        raise BadContractError, "None contract is not allowed to use as argument contract"
      end

      def self.to_s
        "None"
      end
    end
  end
end
