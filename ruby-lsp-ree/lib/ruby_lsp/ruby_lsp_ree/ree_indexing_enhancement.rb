require 'prism'
require_relative "utils/ree_lsp_utils"

module RubyLsp
  module Ree
    class ReeIndexingEnhancement < RubyIndexer::Enhancement
      include RubyLsp::Ree::ReeLspUtils

      REE_INDEXED_OBJECTS = [:fn, :enum, :action, :dao, :bean, :mapper, :aggregate, :async_bean]
      SCHEMA_NODE_NAME = :schema

      def on_call_node_enter(node)
        return unless @listener.current_owner
      
        # remove for now as it breaks go-to-definition for entities
        # if node.name == SCHEMA_NODE_NAME
        #   return index_ree_schema(node)
        # end

        return unless REE_INDEXED_OBJECTS.include?(node.name)
        return unless node.arguments
        return unless node.arguments.child_nodes.first.is_a?(Prism::SymbolNode)

        obj_name = node.arguments.child_nodes.first.unescaped
        return unless current_filename == obj_name

        source = @listener.instance_variable_get(:@source_lines).join
        ast = Prism.parse(source).value # TODO use doc builder

        location = node.location
        signatures = parse_signatures(obj_name, ast)
        documentation = parse_documentation(obj_name, ast)

        comments = "ree_object\ntype: :#{node.name}\n#{documentation}"

        @listener.add_method(
          obj_name,
          location, 
          signatures,
          comments: comments
        )
      end

      private

      def index_ree_schema(node)
        return if node.receiver
        return if !node.arguments || !node.block

        @listener.add_class(
          node.arguments.arguments.first.name.to_s, 
          node.location, 
          node.location, 
          parent_class_name: nil, 
          comments: "ree_schema"
        )
      end

      def parse_signatures(fn_name, ast)
        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        return [] unless class_node

        call_node = class_node.body.body.detect{ |node| node.respond_to?(:name) && node.name == :call }
        return [] unless call_node

        signature_params = signature_params_from_node(call_node.parameters)

        [RubyIndexer::Entry::Signature.new(signature_params)]
      end

      def parse_documentation(fn_name, ast)
        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        return '' unless class_node

        doc_node = class_node.body.body.detect{ |node| node.respond_to?(:name) && node.name == :doc }
        return '' unless doc_node

        str_node = doc_node.arguments.arguments.first

        case str_node
        when Prism::StringNode
          str_node.unescaped
        when Prism::InterpolatedStringNode
          str_node.parts.map(&:unescaped).join
        else
          ''
        end
      rescue => e
        $stderr.puts("error parsing documentation for #{fn_name}: #{e.message} : #{e.backtrace.first}")
        return ''
      end

      def current_filename
        uri = @listener.instance_variable_get(:@uri)
        File.basename(uri.path, '.rb')  
      end
    end
  end
end