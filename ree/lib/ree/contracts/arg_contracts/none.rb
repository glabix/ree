# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class None
      def self.valid?(*)
        raise BadContractError, "None contract is not allowed to use as argument contract"
      end

      def self.to_s
        "None"
      end
    end
  end
end
