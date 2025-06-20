require 'prism'

class RubyLsp::Ree::BasicParser
  def node_name(node)
    return nil unless node.respond_to?(:name)

    node.name
  end

  def get_method_body(node)
    return unless node.body

    if node.body.is_a?(Prism::BeginNode)
      node.body.statements.body
    else
      node.body.body
    end
  end
end