class ReeIndexingEnhancement < RubyIndexer::Enhancement
  REE_PREFIX = '__ree_object_'

  def on_call_node_enter(node)
    return unless @listener.current_owner

    # Return early unless the method call is the one we want to handle
    return unless node.name == :fn
    return unless node.arguments
     
    location = node.location
    fn_name = node.arguments.child_nodes.first.unescaped

    signatures = parse_signatures(fn_name)

    @listener.add_method(
      REE_PREFIX + fn_name,
      location, 
      signatures,
      comments: "ree object"
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