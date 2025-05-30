require_relative 'body_objects_parser'

class RubyLsp::Ree::ConstObjectsParser
  attr_reader :parsed_doc

  def initialize(parsed_doc)
    @parsed_doc = parsed_doc
    @body_parser = RubyLsp::Ree::BodyObjectsParser.new(:const_object)
  end

  def class_const_objects
    const_objects = []
    return unless parsed_doc.has_body?

    const_objects += @body_parser.parse(parsed_doc.class_node.body.body)

    parsed_doc.parse_instance_methods
    parsed_doc.doc_instance_methods.each do |doc_instance_method|
      const_objects += method_const_objects(doc_instance_method)
    end

    const_objects
  end

  def method_const_objects(method_object)
    method_body = method_object.full_method_body
    return [] unless method_body

    const_objects = @body_parser.parse([method_body])

    if method_object.has_contract?
      const_objects += @body_parser.parse([method_object.contract_node])
    end

    const_objects
  end
end