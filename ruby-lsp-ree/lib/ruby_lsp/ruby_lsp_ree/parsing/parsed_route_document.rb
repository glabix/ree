class RubyLsp::Ree::ParsedRouteDocument < RubyLsp::Ree::ParsedClassDocument
  include RubyLsp::Ree::ReeLspUtils

  def initialize(ast, package_name = nil)
    super
    parse_class_includes
    parse_route_options
  end

  def parse_route_options
    @route_options ||= {}
    return unless @class_node

    @routes_node = @class_node.body.body.detect{ node_name(_1) == :routes }
    return if !@routes_node || !@routes_node.block

    @route_opts_node = @routes_node.block.body.body.detect{ node_name(_1) == :opts }
    @route_opts_node.value.elements.each do |assoc_node|
      @route_options[assoc_node.key.unescaped] = assoc_node.value.unescaped
    end
  end

  def has_route_option?(option_name)
    @route_options.has_key?(option_name.to_s)
  end

  def route_option_value(option_name)
    @route_options[option_name.to_s]
  end
end