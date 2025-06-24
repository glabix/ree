# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    class RespondTo
      extend Squarable

      def initialize(*method_names)
        @method_names = method_names
      end

      def valid?(value)
        get_unrespond_list(value).empty?
      end

      def to_s
        "RespondTo#{method_names.inspect}"
      end

      def message(value, name, lvl = 1)
        unrespond_list = get_unrespond_list(value)
        "expected to respond to #{unrespond_list.inspect}}"
      end

      private

      def get_unrespond_list(obj)
        @method_names.reject do |method|
          obj.respond_to?(method)
        end
      end
    end
  end
end
