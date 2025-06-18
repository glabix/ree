require_relative 'basic_parser'
require_relative '../parsed_link_node'
require_relative '../parsed_object_link_node'
require_relative '../parsed_file_path_link_node'

class RubyLsp::Ree::LinksParser < RubyLsp::Ree::BasicParser
  attr_reader :container

  def initialize(container, package_name)
    @container = container
    @document_package_name = package_name
  end

  def parse_links
    nodes = container.select{ |node| node_name(node) == :link || node_name(node) == :import }

    nodes.map do |link_node|
      first_arg = link_node.arguments.arguments.first
      link_node = if first_arg.is_a?(Prism::SymbolNode)
        RubyLsp::Ree::ParsedObjectLinkNode.new(link_node, @document_package_name)
      elsif first_arg.is_a?(Prism::StringNode)
        RubyLsp::Ree::ParsedFilePathLinkNode.new(link_node, @document_package_name)
      else
        raise "not implemented"
      end

      link_node.parse_imports
      link_node
    end
  end
end