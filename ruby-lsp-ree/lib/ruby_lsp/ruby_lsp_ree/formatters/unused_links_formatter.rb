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
        removed_links = 0

        parsed_doc.link_nodes.each do |link_node|
          next if link_node.has_import_section?

          next if source_contains_link_usage?(source_lines, link_node)

          source_lines = remove_link_from_source(source_lines, link_node)
          removed_links += 1
        end

        if removed_links == parsed_doc.link_nodes.size
          source_lines = remove_link_block(source_lines)
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

      def remove_link_block(source_lines)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source_lines.join)
        parsed_doc.parse_links_container_node

        return source_lines unless parsed_doc.links_container_block_node
        
        link_container_start_line = parsed_doc.links_container_node.location.start_line-1
        link_container_after_line = parsed_doc.links_container_node.location.end_line
        block_start = parsed_doc.links_container_block_node.location.start_column-1

        source_lines[link_container_start_line] = source_lines[link_container_start_line][0..block_start] + "\n"
        source_lines[0..link_container_start_line] + source_lines[link_container_after_line..-1]
      end
    end
  end
end