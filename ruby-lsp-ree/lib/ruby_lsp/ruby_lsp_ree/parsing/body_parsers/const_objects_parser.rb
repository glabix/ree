class RubyLsp::Ree::ConstObjectsParser
  attr_reader :parsed_doc

  class ConstObject
    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end

  def initialize(parsed_doc)
    @parsed_doc = parsed_doc
  end

  def class_const_objects
    const_objects = []
    return unless parsed_doc.has_body?

    const_objects += parse_body_const_objects(parsed_doc.class_node.body.body)

    parsed_doc.parse_instance_methods

    parsed_doc.doc_instance_methods.each do |doc_instance_method|
      const_objects += method_const_objects(doc_instance_method)
    end

    const_objects
  end

  def method_const_objects(method_object)
    method_body = method_object.method_body
    return [] unless method_body

    const_objects = parse_body_const_objects(method_body)

    # const_objects.each{ |const_object| const_object.set_method_name(method_object.name) }
    const_objects
  end

  private 

  def parse_body_const_objects(node_body)
    const_objects = []

    node_body.each do |node|
      if node.is_a?(Prism::ConstantReadNode)
        const_objects << ConstObject.new(name: node.name)
      elsif node.is_a?(Prism::CallNode)
        if node.receiver
          receiver = get_first_receiver(node)
      
          if receiver
            const_objects += parse_body_const_objects([receiver])
          end
        end
      
        const_objects += parse_const_objects_from_args(node.arguments)
      else
        if node.respond_to?(:elements)
          const_objects += parse_body_const_objects(node.elements)
        end

        if node.respond_to?(:predicate)
          const_objects += parse_body_const_objects([node.predicate])
        end
        
        if node.respond_to?(:statements)
          const_objects += parse_body_const_objects(node.statements.body)
        end
        
        if node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
          const_objects += parse_body_const_objects(get_method_body(node.block))
        end

        if node.respond_to?(:value) && node.value
          const_objects += parse_body_const_objects([node.value])
        end

        if node.respond_to?(:left) && node.left
          const_objects += parse_body_const_objects([node.left])
        end

        if node.respond_to?(:right) && node.right
          const_objects += parse_body_const_objects([node.right])
        end
      end
    end

    const_objects
  end

  def parse_const_objects_from_args(node_arguments)
    return [] if !node_arguments || !node_arguments.arguments
    parse_body_const_objects(node_arguments.arguments)
  end

  def get_method_body(node)
    return unless node.body

    if node.body.is_a?(Prism::BeginNode)
      node.body.statements.body
    else
      node.body.body
    end
  end

  def get_first_receiver(node)
    return nil unless node.receiver

    if node.receiver.is_a?(Prism::CallNode) && node.receiver.receiver
      return get_first_receiver(node.receiver)
    end

    node.receiver
  end
end