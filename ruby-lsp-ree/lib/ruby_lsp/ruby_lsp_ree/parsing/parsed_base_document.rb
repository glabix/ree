class RubyLsp::Ree::ParsedBaseDocument
  include RubyLsp::Ree::ReeLspUtils

  attr_reader :ast, :package_name, :link_nodes

  def initialize(ast, package_name = nil)
    @ast = ast
    set_package_name(package_name) if package_name
  end

  def set_package_name(package_name)
    @package_name = package_name
  end

  def has_root_class?
    false
  end

  def includes_link_dsl?
    false
  end

  def includes_routes_dsl?
    false
  end

  def includes_linked_object?(obj_name)
    @link_nodes.map(&:name).include?(obj_name)
  end

  def find_link_node(name)
    @link_nodes.detect{ node_name(_1) == name }
  end

  def node_name(node)
    return nil unless node.respond_to?(:name)

    node.name
  end

  def allows_root_links?
    raise "abstract method"
  end

  def has_blank_links_container?
    raise "abstract method"
  end

  def links_container_node
    raise "abstract method"
  end

  def parse_links
    raise "abstract method"
  end
end