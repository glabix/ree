require 'prism'
require_relative 'parsed_document'

class RubyLsp::Ree::ParsedDocumentBuilder
  extend RubyLsp::Ree::ReeLspUtils

  def self.build_from_uri(uri)
    ast = Prism.parse_file(uri.path).value
    document = build_document(ast)

    document.set_package_name(package_name_from_uri(uri))

    document
  end

  def self.build_from_source(source)
    ast = Prism.parse(source).value
    build_document(ast)
  end

  def self.build_document(ast)
    document = RubyLsp::Ree::ParsedDocument.new(ast)
    
    document.parse_class_node
    document.parse_fn_node
    document.parse_class_includes
    document.parse_links

    document
  end   
end