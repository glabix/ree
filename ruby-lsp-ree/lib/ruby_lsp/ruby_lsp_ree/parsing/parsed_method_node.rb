require 'prism'

class RubyLsp::Ree::ParsedMethodNode
  attr_reader :method_node, :contract_node, :nested_local_methods

  def initialize(method_node, contract_node)
    @method_node = method_node
    @contract_node = contract_node
  end

  def name
    @method_node.name
  end

  def has_contract?
    !!@contract_node
  end

  def start_line
    @method_node.location.start_line - 1
  end

  def end_line
    @method_node.location.end_line - 1
  end

  def raised_errors_nested
    return @raised_errors_nested if @raised_errors_nested
    raised = raised_errors
    
    @nested_local_methods.each do |nested_method|
      raised += nested_method.raised_errors_nested
    end

    @raised_errors_nested = raised
  end

  def raised_errors
    return @raised_errors if @raised_errors
    return [] unless @method_node.body

    call_objects = parse_body_call_objects(get_method_body(@method_node))
    raise_objects = call_objects.select{ _1.name == :raise }
    @raised_errors = raise_objects.map{ parse_raised_class_name(_1) }.compact
  end

  def parse_raised_class_name(raise_node)
    return unless raise_node.arguments

    if raise_node.arguments.arguments.first.is_a?(Prism::ConstantReadNode)
      raise_node.arguments.arguments.first.name
    elsif raise_node.arguments.arguments.first.is_a?(Prism::CallNode)
      raise_node.arguments.arguments.first.receiver.name
    else
      nil
    end
  end

  def throws_errors
    return [] unless has_contract?
    return [] unless has_throw_section?

    @contract_node.arguments.arguments.map{ _1.name }
  end

  def has_throw_section?
    @contract_node && @contract_node.name == :throws
  end

  def throw_arguments_end_position
    @contract_node.arguments.arguments.last.location.end_column - 1
  end

  def throw_arguments_end_line
    @contract_node.arguments.arguments.last.location.end_line - 1
  end

  def contract_node_end_position
    @contract_node.location.end_column - 1
  end

  def contract_node_end_line
    @contract_node.location.end_line - 1
  end
  
  def parse_nested_local_methods(local_methods)
    unless @method_node.body
      @nested_local_methods = []
      return
    end

    method_body = get_method_body(@method_node)

    call_nodes = parse_body_call_objects(method_body)
    call_expressions = parse_body_call_expressions(method_body)
    call_node_names = call_nodes.map(&:name) + call_expressions
   
    @nested_local_methods = local_methods.select{ call_node_names.include?(_1.name) }
    @nested_local_methods.each{ _1.parse_nested_local_methods(local_methods) }
  end

  def parse_body_call_objects(node_body)
    call_nodes = []
    
    node_body.each do |node|
      if node.is_a?(Prism::CallNode) && !node.receiver
        call_nodes << node
      elsif node.respond_to?(:statements)
        call_nodes += parse_body_call_objects(node.statements.body)
      elsif node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
        call_nodes += parse_body_call_objects(get_method_body(node.block))
      end
    end

    call_nodes
  end

  def parse_body_call_expressions(node_body)
    call_expressions = []
    
    node_body.each do |node|
      if node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockArgumentNode) && node.block.expression.is_a?(Prism::SymbolNode)
        call_expressions << node.block.expression.unescaped.to_sym
      end
    end

    call_expressions
  end

  def get_method_body(node)
    if node.body.is_a?(Prism::BeginNode)
      node.body.statements.body
    else
      node.body.body
    end
  end
end