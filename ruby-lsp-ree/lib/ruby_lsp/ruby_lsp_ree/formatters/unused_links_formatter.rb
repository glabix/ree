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
        links_count = parsed_doc.link_nodes.size

        parsed_doc.link_nodes.each do |link_node|
          removed_imports = 0

          if link_node.has_import_section?
            link_node.imports.each do |link_import|
              next if source_contains_link_import_usage?(source_lines, link_node, link_import)
              
              source_lines = remove_link_import_from_source(source_lines, link_node, link_import)
              removed_imports += 1
            end

            if link_node.imports.size == removed_imports
              source_lines = remove_link_import_arg_from_source(source_lines, link_node)
            end
          end

          next if source_contains_link_usage?(source_lines, link_node) || link_node.imports.size > removed_imports

          source_lines = remove_link_from_source(source_lines, link_node)
          removed_links += 1
        end

        if removed_links == links_count
          source_lines = remove_link_block(source_lines)
        end

        source_lines.join
      end

      private

      def source_contains_link_usage?(source_lines, link_node)
        source_lines_except_link = source_lines[0...(link_node.location.start_line-1)] + source_lines[(link_node.location.end_line)..-1]
        source_lines_except_link.any?{ |source_line| source_line.match?(/\W#{link_node.name}\W/)}
      end

      def source_contains_link_import_usage?(source_lines, link_node, link_import)
        source_lines_except_link = source_lines[0...(link_node.location.start_line-1)] + source_lines[(link_node.location.end_line)..-1]
        source_lines_except_link.any?{ |source_line| source_line.match?(/\W#{link_import}\W/)}
      end

      def remove_link_from_source(source_lines, link_node)
        ((link_node.location.start_line-1) .. (link_node.location.end_line-1)).each do |i|
          source_lines[i] = ''
        end
        source_lines
      end

      def remove_link_import_from_source(source_lines, link_node, link_import)
        imports_str = link_node.imports.reject{ _1 == link_import}.join(' & ')
        block_start_col = link_node.import_block_open_location.start_column
        block_line = link_node.import_block_open_location.start_line-1
        block_end_line = link_node.import_block_close_location.end_line-1
        source_lines[block_line] = source_lines[block_line][0..block_start_col] + " #{imports_str} }\n"
        ((block_line+1)..block_end_line).each do |i|
          source_lines[i] = ''
        end
        source_lines
      end

      def remove_link_import_arg_from_source(source_lines, link_node)
        link_line = link_node.location.start_line - 1
        link_end_line = link_node.location.end_line - 1
        link_name_end = link_node.first_arg_location.end_column - 1
        source_lines[link_line] = source_lines[link_line][0..link_name_end] + "\n"
        ((link_line+1)..link_end_line).each do |i|
          source_lines[i] = ''
        end
        source_lines
      end

      def remove_link_block(source_lines)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source_lines.join)
        parsed_doc.parse_links_container_node

        return source_lines unless parsed_doc.links_container_block_node
        
        link_container_start_line = parsed_doc.links_container_node.location.start_line-1
        link_container_after_line = parsed_doc.links_container_node.location.end_line
        block_start = parsed_doc.links_container_block_node.location.start_column-1

        source_lines[link_container_start_line] = source_lines[link_container_start_line][0..block_start] + "\n"
        ((link_container_start_line+1) .. link_container_after_line).each do |i|
          source_lines[i] = ''
        end
        source_lines
      end
    end
  end
end