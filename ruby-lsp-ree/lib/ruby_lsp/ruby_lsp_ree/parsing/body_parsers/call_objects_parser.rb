class RubyLsp::Ree::CallObjectsParser
  attr_reader :parsed_doc

  class CallObject
    attr_reader :name, :type, :receiver_name, :method_name

    def initialize(name:, type:, receiver_name: nil)
      @name = name
      @type = type
      @receiver_name = receiver_name
      @method_name = nil
    end

    def set_method_name(method_name)
      @method_name = method_name
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

    call_objects.each{ |call_object| call_object.set_method_name(method_object.name) }
    call_objects
  end

  private 

  def parse_body_call_objects(node_body)
    call_objects = []

    node_body.each do |node|
      if node.is_a?(Prism::CallNode)
        if node.receiver
          receiver = get_first_receiver(node)
      
          if receiver.is_a?(Prism::CallNode)
            call_objects += parse_body_call_objects([receiver])
          end
        else
          call_objects << CallObject.new(name: node.name, type: :method_call)
        end
      
        call_objects += parse_call_objects_from_args(node.arguments)
      else
        if node.respond_to?(:elements)
          call_objects += parse_body_call_objects(node.elements)
        end

        if node.respond_to?(:predicate)
          call_objects += parse_body_call_objects([node.predicate])
        end
        
        if node.respond_to?(:statements)
          call_objects += parse_body_call_objects(node.statements.body)
        end
        
        if node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
          call_objects += parse_body_call_objects(get_method_body(node.block))
        end

        if node.respond_to?(:value) && node.value
          call_objects += parse_body_call_objects([node.value])
        end

        if node.respond_to?(:left) && node.left
          call_objects += parse_body_call_objects([node.left])
        end

        if node.respond_to?(:right) && node.right
          call_objects += parse_body_call_objects([node.right])
        end
      end
    end

    call_objects
  end

  def parse_call_objects_from_args(node_arguments)
    return [] if !node_arguments || !node_arguments.arguments
    parse_body_call_objects(node_arguments.arguments)
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