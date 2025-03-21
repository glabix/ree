module RubyLsp
  module Ree
    class BaseFormatter
      def self.call(source, uri)
        new.call(source, uri)
      end

      def call(source, uri)
        raise 'abstract method'
      end
    end
  end
end