require_relative 'parsed_base_document'
require_relative 'parsed_link_node'
require_relative "body_parsers/links_parser"
require 'ostruct'

class RubyLsp::Ree::ParsedRspecDocument < RubyLsp::Ree::ParsedBaseDocument
  include RubyLsp::Ree::ReeLspUtils

  attr_reader :describe_node

  def initialize(ast, package_name = nil)
    super
    parse_describe_node    
  end

  def allows_root_links?
    true
  end

  def links_container_node
    nil
  end

  def root_node_line_location
    OpenStruct.new(
      start_line: @describe_node.location.start_line,
      end_column: @describe_node.block.opening_loc.end_column
    )
  end

  def has_blank_links_container?
    false
  end

  def parse_describe_node
    @describe_node ||= @ast.statements.body.detect{ |node| node.is_a?(Prism::CallNode) && node.name == :describe }
  end

  def parse_links
    container = @describe_node.block.body.body
    @link_nodes = RubyLsp::Ree::LinksParser.new(container, package_name).parse_links
  end
end