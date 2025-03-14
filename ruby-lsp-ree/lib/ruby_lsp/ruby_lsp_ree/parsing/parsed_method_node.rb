require 'prism'

class RubyLsp::Ree::ParsedMethodNode
  attr_reader :method_node, :contract_node

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

  def raised_errors_nested(source, error_definitions)
    return [] if error_definitions.size == 0
    
    raised = raised_errors(source, error_definitions)
    
    not_detected_errors = error_definitions.select{ !raised.include?(_1.name.to_s) }
    @nested_local_methods.each do |nested_method|
      raised += nested_method.raised_errors_nested(source, not_detected_errors)
      not_detected_errors = error_definitions.select{ !raised.include?(_1.name.to_s) }
    end

    raised
  end

  def raised_errors(source, error_definitions)
    raised = []
    error_names = error_definitions.map(&:name).map(&:to_s)

    source.lines[start_line+1 .. end_line-1].each do |line|
      error_names.each do |error_name|
        regex = /\braise #{Regexp.escape(error_name)}\b/

        if line.match?(regex)
          raised << error_name
        end
      end
    end

    raised.uniq
  end

  def throws_errors
    return [] unless has_contract?
    return [] unless has_throw_section?

    @contract_node.arguments.arguments.map{ _1.name.to_s }
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
  
  def parse_nested_local_methods(local_methods)
    local_method_names = local_methods.map(&:name)
    call_nodes = parse_body_call_objects(@method_node.body.body)
    call_node_names = call_nodes.map(&:name)
   
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
      elsif node.respond_to?(:block) && node.block 
        call_nodes += parse_body_call_objects(node.block.body.body)
      end
    end

    call_nodes
  end
end