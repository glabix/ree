require_relative 'base_formatter'
require_relative '../ree_source_editor'
require_relative '../ree_dsl_parser'

module RubyLsp
  module Ree
    class UnusedLinksFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      attr_reader :editor, :dsl_parser

      def call(source, _uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc

        parsed_doc.parse_links

        @editor = RubyLsp::Ree::ReeSourceEditor.new(source)
        @dsl_parser = RubyLsp::Ree::ReeDslParser.new(parsed_doc, @index)

        links_count = parsed_doc.link_nodes.size

        removed_links = 0

        parsed_doc.link_nodes.each do |link_node|
          remove_imports = []

          link_node.has_import_section?
          if link_node.has_import_section?
            remove_imports = link_node.imports.reject{ |imp| import_is_used?(parsed_doc, link_node, imp) }
            editor.remove_link_imports(link_node, remove_imports)

            if link_node.imports.size == remove_imports.size
              editor.remove_link_import_arg(link_node)
            end
          end

          next if parsed_doc.includes_mapper_dsl?
          
          has_imports = link_node.imports.size > remove_imports.size
          next if has_imports

          remove_objects = link_node.linked_objects.select{ !link_object_is_used?(parsed_doc, link_node, _1) }
          editor.remove_linked_objects(link_node, remove_objects)

          if link_node.linked_objects.size == remove_objects.size 
            editor.remove_link(link_node)
            removed_links += 1
          end
        end

        if removed_links == links_count
          parsed_doc.parse_links_container_node
          editor.remove_link_block(parsed_doc.links_container_node, parsed_doc.links_container_block_node)
        end

        editor.source
      end

      private

      def import_is_used?(parsed_doc, link_node, link_import)
        editor.contains_link_import_usage?(parsed_doc, link_node, link_import) || dsl_parser.contains_object_usage?(link_import)
      end

      def link_object_is_used?(parsed_doc, link_node, linked_object)
        editor.contains_linked_object_usage?(parsed_doc, link_node, linked_object) || dsl_parser.contains_object_usage?(linked_object.usage_name)
      end
    end
  end
end