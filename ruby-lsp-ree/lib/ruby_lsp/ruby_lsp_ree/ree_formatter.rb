module RubyLsp
  module Ree
    class ReeFormatter
      include RubyLsp::Requests::Support::Formatter
      include RubyLsp::Ree::ReeLspUtils

      def initialize
      end

      def run_formatting(uri, document)
        source = document.source
        
        sorted_source = sort_links(source)
        add_missing_error_contracts(source)
      rescue => e
        $stderr.puts("error in ree_formatter: #{e.message} : #{e.backtrace.first}")
      end

      private

      def sort_links(source)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc.link_nodes&.any?

        if parsed_doc.link_nodes.any?{ _1.location.start_line != _1.location.end_line }
          $stderr.puts("multiline link definitions, don't sort")
          return source
        end

        # sort link nodes
        sorted_link_nodes = parsed_doc.link_nodes.sort{ |a, b|
          a_name = a.node.arguments.arguments.first
          b_name = b.node.arguments.arguments.first

          if a_name.is_a?(Prism::SymbolNode) && !b_name.is_a?(Prism::SymbolNode)
            -1
          elsif b_name.is_a?(Prism::SymbolNode) && !a_name.is_a?(Prism::SymbolNode)
            1
          else
            a_name.unescaped <=> b_name.unescaped
          end
        }

        # check if no re-order
        if parsed_doc.link_nodes.map{ _1.node.arguments.arguments.first.unescaped } == sorted_link_nodes.map{ _1.node.arguments.arguments.first.unescaped }
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

      def add_missing_error_contracts(source)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.class_node


        parsed_doc.parse_error_definitions
        parsed_doc.parse_instance_methods

        # pp parsed_doc.doc_instance_methods

        # pp parsed_doc.error_definitions
        # pp parsed_doc.doc_instance_methods

        parsed_doc.doc_instance_methods.select(&:has_contract?).each do |doc_instance_method|
          pp raised_errors = doc_instance_method.raised_errors(source, parsed_doc.error_definitions)
          throws_errors = doc_instance_method.throws_errors

          missed_errors = raised_errors - throws_errors

          add_missed_errors(doc_instance_method, missed_errors)
        end
      end
    end
  end
end
