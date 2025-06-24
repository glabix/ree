# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    class Block
      def self.valid?(_)
        raise BadContractError, "#{to_s} contract is not allowed to use as argument contract"
      end

      def self.to_s
        "Block"
      end
    end
  end
end
