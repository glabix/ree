require 'prism'

class RubyLsp::Ree::CallObjectsParser
  attr_reader :parsed_doc

  class CallObject
    attr_reader :name, :type, :receiver_name

    def initialize(name:, type:, receiver_name: nil)
      @name = name
      @type = type
      @receiver_name = receiver_name
    end
  end

  def initialize(parsed_doc)
    @parsed_doc = parsed_doc
  end

  def class_call_objects
    call_objects = []
    return unless parsed_doc.has_body?

    call_objects += parse_body_call_objects(parsed_doc.class_node.body.body)

    parsed_doc.parse_instance_methods

    parsed_doc.doc_instance_methods.each do |doc_instance_method|
      call_objects += method_call_objects(doc_instance_method)
    end

    call_objects
  end

  def method_call_objects(method_object)
    method_body = method_object.method_body
    return [] unless method_body

    call_nodes = parse_body_call_objects(method_body)
    call_expressions = [] # don't parse call expressions for now parse_body_call_expressions(method_body)

    call_objects = call_nodes + call_expressions

    call_objects
  end

  private 

  def parse_body_call_objects(node_body)
    call_objects = []
    
    node_body.each do |node|
      if node.is_a?(Prism::CallNode)
        receiver_name = node.receiver.respond_to?(:name) ? node.receiver.name : nil
        call_objects << CallObject.new(name: node.name, type: :method_call, receiver_name: receiver_name)
      elsif node.respond_to?(:statements)
        call_objects += parse_body_call_objects(node.statements.body)
      elsif node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
        call_objects += parse_body_call_objects(get_method_body(node.block))
      elsif node.respond_to?(:value) && node.value
        call_objects += parse_body_call_objects([node.value])
      end
    end

    call_objects
  end

  def parse_body_call_expressions(node_body)
    call_expressions = []
    
    node_body.each do |node|
      if node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockArgumentNode) && node.block.expression.is_a?(Prism::SymbolNode)
        call_expressions << CallObject.new(name: node.block.expression.unescaped.to_sym, type: :proc_to_sym)
      end
    end

    call_expressions
  end
end