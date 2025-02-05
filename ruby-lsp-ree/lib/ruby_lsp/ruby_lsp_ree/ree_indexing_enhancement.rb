module RubyLsp
  module Ree
    class ReeIndexingEnhancement < RubyIndexer::Enhancement
      REE_INDEXED_OBJECTS = [:fn, :enum]

      def on_call_node_enter(node)
        return unless @listener.current_owner

        return unless REE_INDEXED_OBJECTS.include?(node.name)
        return unless node.arguments

        # index = @listener.instance_variable_get(:@index)
        
        location = node.location
        obj_name = node.arguments.child_nodes.first.unescaped
        signatures = parse_signatures(obj_name)
        comments = "ree_object\ntype: #{node.name}"
      
        # visibility = RubyIndexer::Entry::Visibility::PUBLIC
        # owner = index['Object'].first

        # index.add(RubyIndexer::Entry::Method.new(
        #   fn_name,
        #   @listener.instance_variable_get(:@uri),
        #   location,
        #   location,
        #   comments,
        #   signatures,
        #   visibility,
        #   owner,
        # ))

        @listener.add_method(
          obj_name,
          location, 
          signatures,
          comments: comments
        )
      end

      def parse_signatures(fn_name)
        uri = @listener.instance_variable_get(:@uri)
        ast = Prism.parse_file(uri.path).value

        class_node = ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
        return [] unless class_node

        call_node = class_node.body.body.detect{ |node| node.name == :call }
        return [] unless call_node
        
        signature_params = @listener.send(:list_params, call_node.parameters)

        [RubyIndexer::Entry::Signature.new(signature_params)]
      end
    end
  end
end