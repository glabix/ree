module RubyLsp
  module Ree
    class BaseFormatter
      def self.call(source, uri, message_queue)
        new(message_queue).call(source, uri)
      end

      def initialize(message_queue)
        @message_queue = message_queue
      end

      def call(source, uri)
        raise 'abstract method'
      end
    end
  end
end