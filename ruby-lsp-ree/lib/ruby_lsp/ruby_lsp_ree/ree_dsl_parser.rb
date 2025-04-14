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
        return false unless @index

        parsed_doc.ree_dsls.any? do |ree_dsl|
          ree_dsl_contains_object_usage?(ree_dsl.name, obj_name)
        end
      end

      private

      def ree_dsl_contains_object_usage?(dsl_name, obj_name)
        dsl_objects = @index[dsl_name]
        return unless dsl_objects

        uris = dsl_objects.map(&:uri)

        uris.any?{ file_contains_object_usage?(_1, obj_name) }
      end

      def file_contains_object_usage?(file_uri, obj_name) 
        file_content = File.read(file_uri.path.to_s)
        file_content.match?(/\W#{obj_name}\W/)
      end
    end
  end
end