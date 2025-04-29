require_relative 'base_formatter'
require_relative "../ree_object_finder"

module RubyLsp
  module Ree
    class ImportPackagesFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, uri)
        return source unless @index

        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source, uri)

        finder = ReeObjectFinder.new(@index)
        editor = RubyLsp::Ree::ReeSourceEditor.new(source)

        current_package = package_name_from_uri(uri)

        parsed_doc.link_nodes.select(&:object_name_type?).each do |link_node|
          next if finder.find_object_for_package(link_node.name, link_node.link_package_name)
            
          ree_objects = finder.find_objects(link_node.name)
          
          if ree_objects.size == 1
            editor.change_link_package(link_node, ree_objects.first.object_package, current_package)
          else
            # add warning
          end
        end

        editor.source
      end
    end
  end
end