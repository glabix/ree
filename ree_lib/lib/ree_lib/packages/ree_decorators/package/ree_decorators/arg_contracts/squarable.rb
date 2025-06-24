# frozen_string_literal: true

module ReeDecorators
  module ArgContracts
    module Squarable
      def [](...)
        new(...)
      end
    end
  end
end
