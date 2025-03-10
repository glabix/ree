require 'prism'
require_relative 'parsed_document'
require_relative 'parsed_rspec_document'

class RubyLsp::Ree::ParsedDocumentBuilder
  extend RubyLsp::Ree::ReeLspUtils

  def self.build_from_uri(uri, type = nil)
    ast = Prism.parse_file(uri.path).value
    document = build_document(ast, type)
    return unless document

    document.set_package_name(package_name_from_uri(uri))

    document
  end

  def self.build_from_ast(ast, uri, type = nil)
    document = build_document(ast, type)
    return unless document

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
      build_detected_document_type(ast)
    end
  end

  def self.build_detected_document_type(ast)
    if has_root_class?(ast)
      build_regular_document(ast)
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

    document.parse_describe_node    
    document.parse_links
    
    document
  end

  def self.build_regular_document(ast)
    document = RubyLsp::Ree::ParsedDocument.new(ast)
    
    document.parse_class_node
    document.parse_fn_node
    document.parse_action_node
    document.parse_bean_node
    document.parse_dao_node
    document.parse_mapper_node
    document.parse_aggregate_node
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