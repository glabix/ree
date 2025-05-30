require_relative 'body_objects_parser'

class RubyLsp::Ree::CallObjectsParser
  attr_reader :parsed_doc

  def initialize(parsed_doc)
    @parsed_doc = parsed_doc
    @body_parser = RubyLsp::Ree::BodyObjectsParser.new(:call_object)
  end

  def class_call_objects
    call_objects = []
    return unless parsed_doc.has_body?

    call_objects += @body_parser.parse(parsed_doc.class_node.body.body)

    parsed_doc.parse_instance_methods
    parsed_doc.doc_instance_methods.each do |doc_instance_method|
      call_objects += method_call_objects(doc_instance_method)
    end

    call_objects
  end

  def method_call_objects(method_object)
    method_body = method_object.full_method_body
    return [] unless method_body

    call_objects = @body_parser.parse([method_body])

    call_objects.each{ |call_object| call_object.set_method_name(method_object.name) }
    call_objects
  end
end