require_relative 'base_formatter'

module RubyLsp
  module Ree
    class MissingImportsFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, _uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.has_root_class?

        pp parsed_doc.parse_call_objects

        source
      end
    end
  end
end