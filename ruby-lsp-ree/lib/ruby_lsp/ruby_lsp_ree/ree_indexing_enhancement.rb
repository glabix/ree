require 'prism'
require_relative "ree_lsp_utils"

module RubyLsp
  module Ree
    class ReeIndexingEnhancement < RubyIndexer::Enhancement
      include RubyLsp::Ree::ReeLspUtils

      REE_INDEXED_OBJECTS = [:fn, :enum, :action, :dao, :bean]

      def on_call_node_enter(node)
        return unless @listener.current_owner

        return unless REE_INDEXED_OBJECTS.include?(node.name)
        return unless node.arguments
        return unless node.arguments.child_nodes.first.is_a?(Prism::SymbolNode)

        obj_name = node.arguments.child_nodes.first.unescaped
        return unless current_filename == obj_name

        location = node.location
        signatures = parse_signatures(obj_name)
        comments = "ree_object\ntype: :#{node.name}"

        @listener.add_method(
          obj_name,
          location, 
          signatures,
          comments: comments
        )
      end

      private

      def parse_signatures(fn_name)
        uri = @listener.instance_variable_get(:@uri)
        ast = Prism.parse_file(uri.path).value

        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        return [] unless class_node

        call_node = class_node.body.body.detect{ |node| node.respond_to?(:name) && node.name == :call }
        return [] unless call_node

        signature_params = signature_params_from_node(call_node.parameters)

        [RubyIndexer::Entry::Signature.new(signature_params)]
      end

      def current_filename
        uri = @listener.instance_variable_get(:@uri)
        File.basename(uri.path, '.rb')  
      end
    end
  end
end