require_relative 'basic_parser'

class RubyLsp::Ree::LocalVariablesParser < RubyLsp::Ree::BasicParser
  attr_reader :parsed_doc, :method_object

  class LocalVariable
    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end

  def initialize(method_obj)
    @method_object = method_obj
  end

  def method_local_variables
    method_body = method_object.method_body
    return [] unless method_body

    parse_body_local_variables(method_body)
  end

  private

  def parse_body_local_variables(node_body)
    local_variables = []
    
    node_body.each do |node|
      if node.is_a?(Prism::LocalVariableWriteNode)
        local_variables << LocalVariable.new(name: node.name)
      elsif node.is_a?(Prism::MultiWriteNode)
        local_variables += node.lefts.map{ |x| LocalVariable.new(name: x.name) }
      elsif node.respond_to?(:statements)
        local_variables += parse_body_local_variables(node.statements.body)
      elsif node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
        local_variables += parse_body_local_variables(get_method_body(node.block))
      end
    end
  
    local_variables
  end
end
