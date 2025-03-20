module RubyLsp
  module Ree
    class BaseFormatter
      def self.call(source)
        new.call(source)
      end

      def call(source)
        raise 'abstrtact method'
      end
    end
  end
end