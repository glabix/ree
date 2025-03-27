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

  def includes_linked_object?(obj_name)
    @link_nodes.map(&:name).include?(obj_name)
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

  def includes_link_dsl?
    raise "abstract method"
  end

  def parse_links
    raise "abstract method"
  end
end