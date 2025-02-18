require 'prism'
require_relative 'parsed_document'

class RubyLsp::Ree::ParsedDocumentBuilder
  extend RubyLsp::Ree::ReeLspUtils

  def self.build_from_uri(uri, type = nil)
    ast = Prism.parse_file(uri.path).value
    document = build_document(ast, type)

    document.set_package_name(package_name_from_uri(uri))

    document
  end

  def self.build_from_ast(ast, uri, type = nil)
    document = build_document(ast, type)

    document.set_package_name(package_name_from_uri(uri))

    document
  end

  def self.build_from_source(source, type = nil)
    ast = Prism.parse(source).value
    build_document(ast, type)
  end

  def self.build_document(ast, type)
    case type
    when :enum
      build_enum_document(ast)
    when :dao
      build_dao_document(ast)
    when :bean
      build_bean_document(ast)
    else
      build_regular_document(ast)
    end
  end

  def self.build_regular_document(ast)
    document = RubyLsp::Ree::ParsedDocument.new(ast)
    
    document.parse_class_node
    document.parse_fn_node
    document.parse_action_node
    document.parse_bean_node
    document.parse_dao_node
    document.parse_mapper_node
    document.parse_class_includes
    document.parse_links

    document
  end   

  def self.build_enum_document(ast)
    document = RubyLsp::Ree::ParsedDocument.new(ast)
    
    document.parse_class_node
    document.parse_values

    document
  end   

  def self.build_dao_document(ast)
    document = RubyLsp::Ree::ParsedDocument.new(ast)
    
    document.parse_class_node
    document.parse_filters

    document
  end  
  
  def self.build_bean_document(ast)
    document = RubyLsp::Ree::ParsedDocument.new(ast)
    
    document.parse_class_node
    document.parse_bean_methods

    document
  end  
end