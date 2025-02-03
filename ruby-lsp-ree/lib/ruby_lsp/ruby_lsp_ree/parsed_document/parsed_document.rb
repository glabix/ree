class RubyLsp::Ree::ParsedDocument
  LINK_DSL_MODULE = 'Ree::LinkDSL'

  attr_reader :ast, :package_name, :class_node, :fn_node, :fn_block_node, :class_includes,
    :link_nodes, :linked_objects

  def initialize(ast)
    @ast = ast
  end

  def includes_link_dsl?
    @class_includes.any?{ _1.name == LINK_DSL_MODULE }
  end

  def includes_linked_constant?(const_name)
    @linked_objects.map(&:imports).flatten.include?(const_name)
  end

  def includes_linked_object?(obj_name)
    @linked_objects.map(&:name).include?(obj_name)
  end

  def has_blank_fn?
    @fn_node && !@fn_block_node
  end

  def set_package_name(package_name)
    @package_name = package_name
  end

  def parse_class_node
    @class_node ||= ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
  end

  def parse_fn_node
    return unless class_node

    @fn_node ||= class_node.body.body.detect{ |node| node.name == :fn }
    @fn_block_node = @fn_node&.block
  end

  def parse_class_includes
    return unless class_node

    @class_includes ||= class_node.body.body.select{ _1.name == :include }.map do |class_include|
      parent_name = class_include.arguments.arguments.first.parent.name.to_s
      module_name = class_include.arguments.arguments.first.name
    
      OpenStruct.new(
        name: [parent_name, module_name].compact.join('::')
      )          
    end
  end

  def parse_linked_objects
    return unless class_node

    @link_nodes ||= if fn_block_node && fn_block_node.body
      fn_block_node.body.body.select{ |node| node.name == :link }
    elsif class_includes.any?{ _1.name == LINK_DSL_MODULE }
      class_node.body.body.select{ |node| node.name == :link }
    else
      []
    end

    @linked_objects ||= @link_nodes.map do |link_node|
      name_arg_node = link_node.arguments.arguments.first

      name_val = case name_arg_node
      when Prism::SymbolNode
        name_arg_node.value
      when Prism::StringNode
        name_arg_node.unescaped
      else
        ""
      end

      OpenStruct.new(
        name: name_val,
        imports: parse_link_node_imports(link_node)
      )
    end

  end

  def parse_link_node_imports(node)
    return [] if node.arguments.arguments.size == 1
    
    last_arg = node.arguments.arguments.last

    if last_arg.is_a?(Prism::KeywordHashNode)
      import_arg = last_arg.elements.detect{ _1.key.unescaped == 'import' }
      return [] unless import_arg

      [import_arg.value.body.body.first.name.to_s]
    elsif last_arg.is_a?(Prism::LambdaNode)
      [last_arg.body.body.first.name.to_s]
    else
      return []
    end
  rescue => e
    $stderr.puts("can't parse imports: #{e.message}")
    return []
  end
end