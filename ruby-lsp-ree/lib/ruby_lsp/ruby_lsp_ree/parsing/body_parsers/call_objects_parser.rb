require 'prism'

class RubyLsp::Ree::CallObjectsParser
  attr_reader :parsed_doc

  class CallObject
    def initialize(name:, type:, receiver_name:)

    end
  end

  def initialize(parsed_doc)
    @parsed_doc = parsed_doc
  end

  def class_call_objects
    call_objects = []
    return unless parsed_doc.has_body?

    call_objects += parse_body_call_objects(parsed_doc.class_node.body.body).map(&:name)

    parsed_doc.parse_instance_methods

    parsed_doc.doc_instance_methods.each do |doc_instance_method|
      call_objects += doc_instance_method.parse_call_objects
    end

    call_objects
  end

  private 

  # TODO duplicates with ParsedMethodNode.parse_body_call_objects
  def parse_body_call_objects(node_body)
    call_nodes = []
    
    node_body.each do |node|
      if node.is_a?(Prism::CallNode) && !node.receiver
        call_nodes << node
      elsif node.respond_to?(:statements)
        call_nodes += parse_body_call_objects(node.statements.body)
      elsif node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
        call_nodes += parse_body_call_objects(get_method_body(node.block))
      elsif node.respond_to?(:value) && node.value
        call_nodes += parse_body_call_objects([node.value])
      end
    end

    call_nodes
  end
end