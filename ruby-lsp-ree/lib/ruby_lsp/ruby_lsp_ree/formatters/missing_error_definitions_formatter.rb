require_relative 'base_formatter'

module RubyLsp
  module Ree
    class MissingErrorDefinitionsFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, _uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.class_node

        parsed_doc.parse_error_definitions
        parsed_doc.parse_instance_methods
        parsed_doc.parse_links
        parsed_doc.parse_defined_classes
        parsed_doc.parse_defined_consts

        existing_error_classes = parsed_doc.error_definition_names + 
          parsed_doc.imported_constants + 
          parsed_doc.defined_classes + 
          parsed_doc.defined_consts

        missed_errors = []
        parsed_doc.doc_instance_methods.each do |doc_instance_method|
          doc_instance_method.parse_nested_local_methods(parsed_doc.doc_instance_methods)

          raised_errors = doc_instance_method.raised_errors_nested

          missed_errors += raised_errors - existing_error_classes
        end

        missed_errors = missed_errors.uniq.reject{ Object.const_defined?(_1) }

        add_missed_error_definitions(source, parsed_doc, missed_errors.uniq)
      end

      private

      def add_missed_error_definitions(source, parsed_doc, missed_errors)
        return source if missed_errors.size == 0

        source_lines = source.lines

        if parsed_doc.error_definitions.size > 0
          change_line = parsed_doc.error_definitions.map{ _1.location.start_line }.max - 1
        else
          change_line = parsed_doc.links_container_node.location.end_line - 1 
          source_lines[change_line] += "\n"
        end

        missed_errors.each do |err|
          source_lines[change_line] += "\s\s#{err} = invalid_param_error(:#{underscore(err)})\n"
        end

        source_lines.join
      end 
    end
  end
end