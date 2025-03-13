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
      raised += nested_method.raised_errors(source, not_detected_errors)
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
    return [] if @contract_node.name != :throws

    @contract_node.arguments.arguments.map{ _1.name.to_s }
  end
end