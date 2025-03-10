require_relative "../utils/ree_lsp_utils"
require_relative "../ree_object_finder"
require_relative "../parsing/parsed_link_node"
require_relative "../parsing/parsed_document_builder"

module RubyLsp
  module Ree
    class DefinitionHandler
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      def initialize(index, uri, node_context)
        @index = index
        @uri = uri
        @node_context = node_context
        @finder = ReeObjectFinder.new(@index)
      end

      def get_constant_definition_items(node)
        result = []

        link_nodes = if @node_context.parent.is_a?(Prism::CallNode) && @node_context.parent.name == :link
          # inside link node
          link_node = RubyLsp::Ree::ParsedLinkNode.new(@node_context.parent)
          link_node.parse_imports
          [link_node]
        else
          parsed_doc = if @node_context.parent.is_a?(Prism::CallNode)
            RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(@uri)
          else
            RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@node_context.parent, @uri)
          end

          parsed_doc.link_nodes
        end
        
        link_nodes.each do |link_node|
          if link_node.imports.include?(node.name.to_s)
            uri = ''
            if link_node.file_path_type?
              path = find_local_file_path(link_node.name)  
              next unless path

              uri = File.join(Dir.pwd, path)
            else
              package_name = link_node.link_package_name || package_name_from_uri(@uri)

              method_candidates = @index[link_node.name]
              next if !method_candidates || method_candidates.size == 0
        
              method = method_candidates.detect{ package_name_from_uri(_1.uri) == package_name }
              next unless method

              uri = method.uri.to_s
            end

            result << Interface::Location.new(
              uri: uri,
              range: Interface::Range.new(
                start: Interface::Position.new(line: 0, character: 0),
                end: Interface::Position.new(line: 0, character: 0),
              ),
            )
          end
        end

        result
      end

      def get_ree_objects_definition_items(node)
        message = node.message
        result = []
        
        definition_item = ReeObjectFinder.new(@index).find_object(message)
        return [] unless definition_item

        definition_uri = definition_item.uri.to_s
        return [] unless definition_uri

        result << Interface::Location.new(
          uri: definition_uri,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        result
      end

      def get_linked_object_definition_items(node)
        result = []
        parent_node = @node_context.parent
        return [] unless parent_node.name == :link

        link_node = RubyLsp::Ree::ParsedLinkNode.new(parent_node, package_name_from_uri(@uri))
        package_name = link_node.link_package_name

        method_candidates = @index[node.unescaped]
        return [] if !method_candidates || method_candidates.size == 0
        
        method = method_candidates.detect{ package_name_from_uri(_1.uri) == package_name }
        return [] unless method

        result << Interface::Location.new(
          uri: method.uri.to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        result
      end

      def get_linked_filepath_definition_items(node)
        result = []
        local_path = find_local_file_path(node.unescaped)

        return [] unless local_path

        result << Interface::Location.new(
          uri: File.join(Dir.pwd, local_path),
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )
      end
    end
  end
end