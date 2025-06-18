require_relative 'base_formatter'

module RubyLsp
  module Ree
    class SortLinksFormatter < BaseFormatter
      def call(source, _uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.link_nodes&.any?

        if parsed_doc.link_nodes.any?{ _1.location.start_line != _1.location.end_line }
          $stderr.puts("multiline link definitions, don't sort")
          return source
        end

        # sort link nodes
        sorted_link_nodes = parsed_doc.link_nodes.sort{ |a, b|
          a_name = a.node.arguments.arguments.first
          b_name = b.node.arguments.arguments.first

          if a.class == b.class
            if a_name.respond_to?(:unescaped) && b_name.respond_to?(:unescaped)
              a_name.unescaped <=> b_name.unescaped
            else
              0  
            end
          else
            sort_by_type(a, b)
          end
        }

        # check if no re-order
        if parsed_doc.link_nodes == sorted_link_nodes
          return source
        end

        # insert nodes to source
        link_lines = parsed_doc.link_nodes.map{ _1.location.start_line }

        source_lines = source.lines

        sorted_lines = sorted_link_nodes.map do |sorted_link|
          source_lines[sorted_link.location.start_line - 1]
        end

        link_lines.each_with_index do |link_line, index|
          source_lines[link_line - 1] = sorted_lines[index]
        end

        source_lines.join()
      end

      def sort_by_type(a, b)
        return -1 if a.object_name_type?
        return 1 if b.object_name_type?
          
        return -1 if a.file_path_type?
        return 1 if b.file_path_type?
            
        0
      end
    end
  end
end