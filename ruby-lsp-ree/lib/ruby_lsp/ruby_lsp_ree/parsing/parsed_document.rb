require_relative 'parsed_link_node'

class RubyLsp::Ree::ParsedDocument
  LINK_DSL_MODULE = 'Ree::LinkDSL'

  attr_reader :ast, :package_name, :class_node, :fn_node, :fn_block_node, :class_includes,
    :link_nodes, :values

  def initialize(ast)
    @ast = ast
  end

  def includes_link_dsl?
    @class_includes.any?{ _1.name == LINK_DSL_MODULE }
  end

  def includes_linked_constant?(const_name)
    @link_nodes.map(&:imports).flatten.include?(const_name)
  end

  def includes_linked_object?(obj_name)
    @link_nodes.map(&:name).include?(obj_name)
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

  def parse_links
    return unless class_node

    nodes = if fn_block_node && fn_block_node.body
      fn_block_node.body.body.select{ |node| node.name == :link }
    elsif class_includes.any?{ _1.name == LINK_DSL_MODULE }
      class_node.body.body.select{ |node| node.name == :link }
    else
      []
    end

    @link_nodes = nodes.map do |link_node|
      link_node = RubyLsp::Ree::ParsedLinkNode.new(link_node, package_name)
      link_node.parse_imports
      link_node
    end
  end

  def parse_values
    return unless class_node
    
    @values ||= class_node.body.body
      .select{ _1.name == :val }
      .map{ OpenStruct.new(name: _1.arguments.arguments.first.unescaped) }
  end

  def get_class_name
    name_parts = [class_node.constant_path&.parent&.name, class_node.constant_path.name]
    name_parts.compact.map(&:to_s).join('::')
  end
end