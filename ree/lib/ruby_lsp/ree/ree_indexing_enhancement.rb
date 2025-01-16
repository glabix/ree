class ReeIndexingEnhancement < RubyIndexer::Enhancement
  def on_call_node_enter(node)
    return unless @listener.current_owner

    # Return early unless the method call is the one we want to handle
    return unless node.name == :fn
     
    location = node.location
    
    @listener.add_method(
      node.arguments.child_nodes.first.unescaped,
      location, 
      []
    )
  end
end