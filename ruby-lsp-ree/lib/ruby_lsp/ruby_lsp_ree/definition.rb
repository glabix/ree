require_relative "ree_lsp_utils"
require_relative "parsing/parsed_link_node"

module RubyLsp
  module Ree
    class Definition
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @node_context = node_context
        @nesting = node_context.nesting
        @index = index
        @uri = uri

        dispatcher.register(self, :on_call_node_enter, :on_symbol_node_enter, :on_string_node_enter, :on_constant_read_node_enter)
      end

      def on_constant_read_node_enter(node)
        link_nodes = if @node_context.parent.is_a?(Prism::CallNode)
          # inside link node
          link_node = RubyLsp::Ree::ParsedLinkNode.new(@node_context.parent)
          link_node.parse_imports
          [link_node]
        else
          parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@node_context.parent, @uri)
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

            @response_builder << Interface::Location.new(
              uri: uri,
              range: Interface::Range.new(
                start: Interface::Position.new(line: 0, character: 0),
                end: Interface::Position.new(line: 0, character: 0),
              ),
            )
          end
        end
      end

      def on_call_node_enter(node)
        message = node.message
        return unless message

        method = @index[message].detect{ !_1.location.nil? }
        return unless method

        @response_builder << Interface::Location.new(
          uri: method.uri.to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        nil
      end

      def on_symbol_node_enter(node)
        parent_node = @node_context.parent
        return unless parent_node.name == :link

        link_node = RubyLsp::Ree::ParsedLinkNode.new(parent_node, package_name_from_uri(@uri))
        package_name = link_node.link_package_name

        method_candidates = @index[node.unescaped]
        return if !method_candidates || method_candidates.size == 0
        
        method = method_candidates.detect{ package_name_from_uri(_1.uri) == package_name }
        return unless method

        @response_builder << Interface::Location.new(
          uri: method.uri.to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        nil
      end

      def on_string_node_enter(node)
        local_path = find_local_file_path(node.unescaped)

        if local_path
          @response_builder << Interface::Location.new(
            uri: File.join(Dir.pwd, local_path),
            range: Interface::Range.new(
              start: Interface::Position.new(line: 0, character: 0),
              end: Interface::Position.new(line: 0, character: 0),
            ),
          )
        end

        nil
      end
    end
  end
end