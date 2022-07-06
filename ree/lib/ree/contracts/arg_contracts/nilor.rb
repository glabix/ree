# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class Nilor < Or
      def initialize(*)
        super
        validators << Validators.fetch_for(nil)
      end

      def to_s
        "Nilor[#{validators[0..-2].map(&:to_s).join(', ')}]"
      end
    end
  end
end
