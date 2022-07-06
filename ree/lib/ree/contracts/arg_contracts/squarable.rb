# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    module Squarable
      def [](*args, **kwargs)
        new(*args, **kwargs)
      end
    end
  end
end
