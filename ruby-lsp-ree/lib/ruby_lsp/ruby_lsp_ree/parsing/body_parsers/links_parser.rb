require_relative 'basic_parser'
require_relative '../parsed_link_node_builder'

class RubyLsp::Ree::LinksParser < RubyLsp::Ree::BasicParser
  attr_reader :container

  def initialize(container, package_name)
    @container = container
    @document_package_name = package_name
  end

  def parse_links
    nodes = container.select{ |node| node_name(node) == :link || node_name(node) == :import }

    nodes.map do |link_node|
      RubyLsp::Ree::ParsedLinkNodeBuilder.build_from_node(link_node, @document_package_name)
    end
  end
end