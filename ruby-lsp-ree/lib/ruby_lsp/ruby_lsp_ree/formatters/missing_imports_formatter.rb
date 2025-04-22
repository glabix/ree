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

        fn_calls = parsed_doc.parse_fn_calls
        filtered_fn_calls = filter_fn_calls(parsed_doc, fn_calls)
        objects_to_add = filtered_fn_calls.map{ |fn_call|
          finder.find_object(fn_call.name.to_s)
        }.compact

        bean_calls = parsed_doc.parse_bean_calls
        filtered_bean_calls = filter_bean_calls(parsed_doc, bean_calls)
        objects_to_add += filtered_bean_calls.map{ |bean_call|
          finder.find_object(bean_call.receiver_name.to_s)
        }.compact

        return editor.source if objects_to_add.size == 0
        
        editor.add_links(parsed_doc, objects_to_add, current_package)
        editor.source
      end

      private

      def filter_fn_calls(parsed_doc, fn_calls)
        #TODO implement
        fn_calls
      end

      def filter_bean_calls(parsed_doc, bean_calls)
        #TODO implement
        bean_calls
      end
    end
  end
end