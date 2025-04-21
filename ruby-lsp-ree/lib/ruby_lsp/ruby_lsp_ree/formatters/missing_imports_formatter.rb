require_relative 'base_formatter'
require_relative "../ree_object_finder"

module RubyLsp
  module Ree
    class MissingImportsFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, uri)
        return source unless @index

        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.has_root_class?

        finder = ReeObjectFinder.new(@index)
        editor = RubyLsp::Ree::ReeSourceEditor.new(source)

        current_package = package_name_from_uri(uri)

        call_objects = parsed_doc.parse_call_objects

        pp call_objects

        filtered_call_objects = filter_call_objects(parsed_doc, call_objects)
        filtered_call_objects.each do |call_object|
          ree_object = finder.find_object(call_object.to_s)

          if ree_object
            editor.add_link(parsed_doc, ree_object, current_package)
          end
        end

        editor.source
      end

      private

      def filter_call_objects(parsed_doc, call_objects)
        #TODO implement
        call_objects
      end
    end
  end
end