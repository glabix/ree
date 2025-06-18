require 'prism'
require_relative 'parsed_link_node'
require_relative 'parsed_object_link_node'
require_relative 'parsed_file_path_link_node'

class RubyLsp::Ree::ParsedLinkNodeBuilder
  def self.build_from_node(node, package_name)
    first_arg = node.arguments.arguments.first
    
    link_node = if first_arg.is_a?(Prism::SymbolNode)
      RubyLsp::Ree::ParsedObjectLinkNode.new(node, package_name)
    elsif first_arg.is_a?(Prism::StringNode)
      RubyLsp::Ree::ParsedFilePathLinkNode.new(node, package_name)
    else
      raise "not implemented"
    end

    link_node.parse_imports
    link_node
  end
end