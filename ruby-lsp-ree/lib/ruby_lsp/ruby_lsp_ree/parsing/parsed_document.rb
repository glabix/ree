require_relative 'parsed_link_node'
require 'ostruct'

class RubyLsp::Ree::ParsedDocument
  include RubyLsp::Ree::ReeLspUtils

  LINK_DSL_MODULE = 'Ree::LinkDSL'

  attr_reader :ast, :package_name, :class_node, :fn_node, :class_includes,
    :link_nodes, :values, :action_node, :dao_node, :filters,
    :bean_node, :bean_methods, :mapper_node, :links_container_block_node, :aggregate_node

  def initialize(ast)
    @ast = ast
  end

  def links_container_node
    # TODO don't use separate node, use one field for all and additional type field: links_container_node_type
    @fn_node || @action_node || @dao_node || @bean_node || @mapper_node || @aggregate_node
  end

  def allows_root_links?
    false
  end

  def includes_link_dsl?
    @class_includes.any?{ node_name(_1) == LINK_DSL_MODULE }
  end

  def includes_linked_constant?(const_name)
    @link_nodes.map(&:imports).flatten.include?(const_name)
  end

  def includes_linked_object?(obj_name)
    @link_nodes.map{ node_name(_1) }.include?(obj_name)
  end

  def find_link_node(name)
    @link_nodes.detect{ node_name(_1) == name }
  end

  def find_link_with_imported_object(name)
    @link_nodes.detect do |link_node|
      link_node.imports.include?(name)
    end
  end

  def find_import_for_package(name, package_name)
    @link_nodes.detect do |link_node|
      link_node.imports.include?(name) && link_node.link_package_name == package_name
    end
  end

  def has_blank_links_container?
    links_container_node && !@links_container_block_node
  end

  def set_package_name(package_name)
    @package_name = package_name
  end

  def parse_class_node
    @class_node ||= ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
  end

  def parse_fn_node
    return unless class_node

    @fn_node ||= class_node.body.body.detect{ |node| node_name(node) == :fn }
    @links_container_block_node ||= @fn_node&.block
  end

  def parse_action_node
    return unless class_node

    @action_node ||= class_node.body.body.detect{ |node| node_name(node) == :action }
    @links_container_block_node ||= @action_node&.block
  end

  def parse_dao_node
    return unless class_node

    @dao_node ||= class_node.body.body.detect{ |node| node_name(node) == :dao }
    @links_container_block_node ||= @dao_node&.block
  end

  def parse_bean_node
    return unless class_node

    @bean_node ||= class_node.body.body.detect{ |node| node_name(node) == :bean }
    @links_container_block_node ||= @bean_node&.block
  end

  def parse_mapper_node
    return unless class_node

    @mapper_node ||= class_node.body.body.detect{ |node| node_name(node) == :mapper }
    @links_container_block_node ||= @mapper_node&.block
  end

  def parse_aggregate_node
    return unless class_node

    @aggregate_node ||= class_node.body.body.detect{ |node| node_name(node) == :aggregate }
    @links_container_block_node ||= @aggregate_node&.block
  end

  def parse_class_includes
    return unless class_node

    @class_includes ||= class_node.body.body.select{ node_name(_1) == :include }.map do |class_include|
      parent_name = class_include.arguments.arguments.first.parent.name.to_s
      module_name = class_include.arguments.arguments.first.name
    
      OpenStruct.new(
        name: [parent_name, module_name].compact.join('::')
      )          
    end
  end

  def parse_links
    return unless class_node

    nodes = if links_container_node && @links_container_block_node && @links_container_block_node.body
      @links_container_block_node.body.body.select{ |node| node_name(node) == :link }
    elsif class_includes.any?{ node_name(_1) == LINK_DSL_MODULE }
      class_node.body.body.select{ |node| node_name(node) == :link }
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
      .select{ node_name(_1) == :val }
      .map{ OpenStruct.new(name: _1.arguments.arguments.first.unescaped) }
  end

  def parse_filters
    return unless class_node
    
    @filters ||= class_node.body.body
      .select{ node_name(_1) == :filter }
      .map{ OpenStruct.new(name: _1.arguments.arguments.first.unescaped, signatures: parse_filter_signature(_1)) }

  end

  def parse_bean_methods
    return unless class_node
    
    @bean_methods ||= class_node.body.body
      .select{ _1.is_a?(Prism::DefNode) }
      .map{ OpenStruct.new(name: node_name(_1).to_s, signatures: parse_signatures_from_params(_1.parameters)) }
  end

  def parse_filter_signature(filter_node)
    return [] unless filter_node

    lambda_node = filter_node.arguments&.arguments[1]
    return [] unless lambda_node

    parse_signatures_from_params(lambda_node.parameters.parameters)
  end

  def parse_signatures_from_params(parameters)
    signature_params = signature_params_from_node(parameters)
    [RubyIndexer::Entry::Signature.new(signature_params)]
  end

  def class_name
    class_node.constant_path.name.to_s
  end

  def module_name
    class_node.constant_path&.parent&.name.to_s
  end

  def full_class_name
    name_parts = [class_node.constant_path&.parent&.name, class_node.constant_path.name]
    name_parts.compact.map(&:to_s).join('::')
  end

  def links_container_node_name
    links_container_node.arguments.arguments.first.unescaped
  end

  def node_name(node)
    return nil unless node.respond_to?(:name)

    node.name
  end
end