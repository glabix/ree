module RubyLsp
  module Ree
    class BaseFormatter
      def self.call(source, uri, message_queue, index)
        new(message_queue, index).call(source, uri)
      rescue => e
        $stderr.puts("error in #{self.class}: #{e.message} : #{e.backtrace.first}")
        source
      end

      def initialize(message_queue, index)
        @message_queue = message_queue
        @index = index
      end

      def call(source, uri)
        raise 'abstract method'
      end
    end
  end
end