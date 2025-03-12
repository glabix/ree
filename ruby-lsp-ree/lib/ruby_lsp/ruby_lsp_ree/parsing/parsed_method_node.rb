require 'prism'

class RubyLsp::Ree::ParsedMethodNode
  attr_reader :method_node, :contract_node

  def initialize(method_node, contract_node)
    @method_node = method_node
    @contract_node = contract_node
  end

  def has_contract?
    !!@contract_node
  end
end