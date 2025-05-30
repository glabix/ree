require 'prism'

class RubyLsp::Ree::BodyObjectsParser
  class ConstObject
    attr_reader :name

    def initialize(name:)
      @name = name
    end
  end

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

    def has_receiver?
      !!@receiver_name
    end
  end

  def initialize(target_type)
    @target_type = target_type
  end

  def parse(nodes)
    target_objects = []

    return target_objects unless nodes

    nodes.each do |node|
      next if node.is_a?(Prism::DefNode) # for now don't step into method, parse each method separately
      
      if node.is_a?(Prism::ConstantReadNode) && @target_type == :const_object
        target_objects << ConstObject.new(name: node.name)
      end

      if node.is_a?(Prism::CallNode)
        if node.receiver
          target_objects += parse([node.receiver])
        else
          next if node.name == :link # don't parse objects inside links

          if @target_type == :call_object
            target_objects << CallObject.new(name: node.name, type: :method_call)
          end
        end
      
        target_objects += parse_target_objects_from_args(node.arguments)
      else
        if node.respond_to?(:elements)
          target_objects += parse(node.elements)
        end

        if node.respond_to?(:predicate)
          target_objects += parse([node.predicate])
        end
        
        if node.respond_to?(:statements)
          target_objects += parse([node.statements])
        end

        if node.respond_to?(:subsequent)
          target_objects += parse([node.subsequent])
        end

        if node.respond_to?(:value) && node.value
          target_objects += parse([node.value])
        end

        if node.respond_to?(:key) && node.key
          target_objects += parse([node.key])
        end

        if node.respond_to?(:left) && node.left
          target_objects += parse([node.left])
        end

        if node.respond_to?(:right) && node.right
          target_objects += parse([node.right])
        end

        if node.respond_to?(:parts) && node.parts
          target_objects += parse(node.parts)
        end

        if node.respond_to?(:rescue_clause) && node.rescue_clause
          target_objects += parse([node.rescue_clause])
        end

        if node.respond_to?(:else_clause) && node.else_clause
          target_objects += parse([node.else_clause])
        end

        if node.respond_to?(:ensure_clause) && node.ensure_clause
          target_objects += parse([node.ensure_clause])
        end

        if node.respond_to?(:body) && node.body
          if node.body.is_a?(Array)
            target_objects += parse(node.body)
          else
            target_objects += parse([node.body])
          end
        end
      end

      if node.respond_to?(:block) && node.block && node.block.is_a?(Prism::BlockNode)
        if node.block.body.is_a?(Array)
          target_objects += parse(node.block.body)
        else
          target_objects += parse([node.block.body])
        end
      end
    end

    target_objects
  end

  private

  def parse_target_objects_from_args(node_arguments)
    return [] if !node_arguments || !node_arguments.arguments
    parse(node_arguments.arguments)
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
