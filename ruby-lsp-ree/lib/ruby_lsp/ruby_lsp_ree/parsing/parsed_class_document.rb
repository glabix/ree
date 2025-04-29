require_relative 'parsed_base_document'
require_relative 'parsed_link_node'
require_relative 'parsed_method_node'
require_relative "../ree_constants"
require_relative "body_parsers/call_objects_parser"

require 'ostruct'

class RubyLsp::Ree::ParsedClassDocument < RubyLsp::Ree::ParsedBaseDocument
  include RubyLsp::Ree::ReeLspUtils
  include RubyLsp::Ree::ReeConstants

  attr_reader :class_node, :class_includes, 
    :values, :filters, :bean_methods, :links_container_block_node, :error_definitions, 
    :error_definition_names, :doc_instance_methods, :links_container_node, 
    :defined_classes, :defined_consts

  def initialize(ast, package_name = nil)
    super
    parse_class_node    
  end

  def has_root_class?
    true
  end

  def allows_root_links?
    false
  end

  def has_body?
    class_node && class_node.body && class_node.body.body
  end

  def includes_link_dsl?
    @class_includes.any?{ node_name(_1) == LINK_DSL_MODULE }
  end

  def includes_routes_dsl?
    @class_includes.any?{ node_name(_1) == ROUTES_DSL_MODULE }
  end

  def includes_mapper_dsl?
    @class_includes.any?{ node_name(_1) == MAPPER_DSL_MODULE }
  end

  def includes_ree_dsl?
    ree_dsls.size > 0
  end

  def includes_linked_constant?(const_name)
    @link_nodes.map(&:imports).flatten.include?(const_name)
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

  def parse_class_node
    @class_node ||= ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
  end

  def parse_links_container_node
    return unless has_body?

    @links_container_node ||= class_node.body.body.detect{ |node| LINKS_CONTAINER_TYPES.include?(node_name(node)) }
    @links_container_node_type = node_name(@links_container_node)
    @links_container_block_node ||= @links_container_node&.block
  end

  def parse_class_includes
    return unless has_body?

    @class_includes ||= class_node.body.body.select{ node_name(_1) == :include }.map do |class_include|
      first_arg = class_include.arguments.arguments.first

      include_name = case first_arg
      when Prism::ConstantPathNode
        parent_name = class_include.arguments.arguments.first.parent.name.to_s
        module_name = class_include.arguments.arguments.first.name

        [parent_name, module_name].compact.join('::')
      when Prism::ConstantReadNode
        first_arg.name.to_s
      else
        ''
      end
    
      OpenStruct.new(
        name: include_name, location: class_include.location
      )          
    end
  end

  def parse_links
    return unless has_body?

    nodes = if links_container_node && @links_container_block_node && @links_container_block_node.body
      @links_container_block_node.body.body.select{ |node| node_name(node) == :link }
    elsif class_includes.any?{ node_name(_1) == LINK_DSL_MODULE }
      class_node.body.body.select{ |node| node_name(node) == :link }
    else
      []
    end

    @link_nodes = nodes.map do |link_node|
      link_node = RubyLsp::Ree::ParsedLinkNode.new(link_node, package_name)
      link_node.parse_imports # TODO move parse imports inside link_node constructor
      link_node
    end
  end

  def parse_values
    return unless has_body?
    
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
    return unless has_body?

    @bean_methods ||= class_node.body.body
      .select{ _1.is_a?(Prism::DefNode) }
      .map{ OpenStruct.new(name: node_name(_1).to_s, signatures: parse_signatures_from_params(_1.parameters)) }
  end

  def parse_instance_methods
    return if @doc_instance_methods
    @doc_instance_methods = []

    current_contract_node = nil
    class_node.body.body.each do |node|
      if node.is_a?(Prism::CallNode) && CONTRACT_CALL_NODE_NAMES.include?(node_name(node))
        current_contract_node = node
      else
        if node.is_a?(Prism::DefNode)
          @doc_instance_methods << RubyLsp::Ree::ParsedMethodNode.new(node, current_contract_node)
        end

        current_contract_node = nil
      end
    end

    @doc_instance_methods
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

  def parse_error_definitions
    return unless has_body?

    @error_definitions = class_node.body.body
      .select{ _1.is_a?(Prism::ConstantWriteNode) }
      .select{ ERROR_DEFINITION_NAMES.include?(node_name(_1.value)) }

    @error_definition_names = @error_definitions.map(&:name)
  end

  def parse_defined_classes
    @defined_classes = []
    return unless has_body?

    @defined_classes = class_node.body.body
      .select{ _1.is_a?(Prism::ClassNode) }
      .map(&:name)
  end
    
  def parse_defined_consts
    @defined_consts = []
    return unless has_body?

    @defined_consts += class_node.body.body
      .select{ _1.is_a?(Prism::ConstantWriteNode) }
      .map(&:name)
  end

  def parse_method_calls
    RubyLsp::Ree::CallObjectsParser.new(self).class_call_objects
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

  def imported_constants
    @link_nodes.map(&:imports).flatten.map(&:to_sym)
  end

  def ree_dsls
    @class_includes.select{ node_name(_1).downcase.match?(/ree/) && node_name(_1).downcase.match?(/dsl/)}
  end
end