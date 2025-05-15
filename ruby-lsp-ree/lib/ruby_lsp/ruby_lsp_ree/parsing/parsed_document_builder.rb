require 'prism'
require_relative 'parsed_class_document'
require_relative 'parsed_rspec_document'
require_relative 'parsed_route_document'
require_relative 'parsed_entity_document'
require_relative 'parsed_dao_document'

class RubyLsp::Ree::ParsedDocumentBuilder
  extend RubyLsp::Ree::ReeLspUtils

  def self.build_from_uri(uri, type = nil)
    return unless is_ruby_file?(uri)
    
    ast = Prism.parse_file(uri.path).value
    document = build_document(ast, type, package_name_from_uri(uri))
    return unless document

    document
  end

  def self.build_from_ast(ast, uri, type = nil)
    return if uri && !is_ruby_file?(uri)

    document = build_document(ast, type, package_name_from_uri(uri))
    return unless document

    document
  end

  def self.build_from_source(source, type: nil, package_name: nil)
    ast = Prism.parse(source).value
    build_document(ast, type, package_name)
  end

  def self.build_document(ast, type, package_name = nil)
    case type
    when :enum
      build_enum_document(ast)
    when :dao
      build_dao_document(ast)
    when :bean
      build_bean_document(ast)
    when :route
      build_route_document(ast)
    when :entity
      build_entity_document(ast)
    else
      build_detected_document_type(ast, package_name)
    end
  end

  def self.build_detected_document_type(ast, package_name = nil)
    if has_root_class?(ast)
      build_class_document(ast, package_name)
    elsif has_root_rspec_call?(ast)
      build_rspec_document(ast)
    else 
      nil
    end
  end

  def self.has_root_class?(ast)
    !!ast.statements.body.detect{ |node| node.is_a?(Prism::ClassNode) }
  end

  def self.has_root_rspec_call?(ast)
    ast.statements.body.detect{ |node| node.is_a?(Prism::CallNode) && node.name == :describe }
  end

  def self.build_rspec_document(ast)
    document = RubyLsp::Ree::ParsedRspecDocument.new(ast)
    document.parse_links
    
    document
  end

  def self.build_class_document(ast, package_name)
    document = RubyLsp::Ree::ParsedClassDocument.new(ast, package_name)
    
    document.parse_links_container_node
    document.parse_class_includes
    document.parse_links

    document
  end   

  def self.build_enum_document(ast)
    document = RubyLsp::Ree::ParsedClassDocument.new(ast)
    
    document.parse_class_node
    document.parse_values

    document
  end   
  
  def self.build_bean_document(ast)
    document = RubyLsp::Ree::ParsedClassDocument.new(ast)
    
    document.parse_class_node
    document.parse_bean_methods

    document
  end  

  def self.build_dao_document(ast)
    RubyLsp::Ree::ParsedDaoDocument.new(ast)
  end  

  def self.build_route_document(ast)
    RubyLsp::Ree::ParsedRouteDocument.new(ast)
  end

  def self.build_entity_document(ast)
    RubyLsp::Ree::ParsedEntityDocument.new(ast)
  end

  def self.is_ruby_file?(uri)
    File.extname(uri.to_s) == '.rb'
  end
end