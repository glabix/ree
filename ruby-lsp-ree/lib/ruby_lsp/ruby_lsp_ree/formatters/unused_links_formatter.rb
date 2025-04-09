require_relative 'base_formatter'

module RubyLsp
  module Ree
    class UnusedLinksFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils

      def call(source, _uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.class_node

        parsed_doc.parse_links

        source_lines = source.lines

        parsed_doc.link_nodes.each do |link_node|
          next if link_node.has_import_section?

          next if source_contains_link_usage?(source_lines, link_node)

          source_lines = remove_link_from_source(source_lines, link_node)
        end

        source_lines.join
      end

      private

      def source_contains_link_usage?(source_lines, link_node)
        source_lines_except_link = source_lines[0...(link_node.location.start_line-1)] + source_lines[(link_node.location.end_line)..-1]
        source_lines_except_link.any?{ |source_line| source_line.match?(/\W#{link_node.name}\W/)}
      end

      def remove_link_from_source(source_lines, link_node)
        source_lines[0...(link_node.location.start_line-1)] + source_lines[(link_node.location.end_line)..-1]
      end
    end
  end
end