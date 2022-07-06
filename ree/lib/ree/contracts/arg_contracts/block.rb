# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Block
      def self.valid?(*)
        raise BadContractError, "#{name} contract is not allowed to use as argument contract"
      end

      def to_s
        "Block"
      end
    end
  end
end
