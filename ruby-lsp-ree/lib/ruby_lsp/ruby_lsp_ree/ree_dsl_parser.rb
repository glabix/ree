module RubyLsp
  module Ree
    class ReeDslParser
      include RubyLsp::Ree::ReeLspUtils

      attr_reader :parsed_doc

      def initialize(parsed_doc, index)
        @parsed_doc = parsed_doc
        @index = index
      end

      def contains_object_usage?(obj_name)
        false
      end
    end
  end
end