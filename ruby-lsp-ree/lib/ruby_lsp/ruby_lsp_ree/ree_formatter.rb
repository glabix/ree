module RubyLsp
  module Ree
    class ReeFormatter
      include RubyLsp::Requests::Support::Formatter
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      def initialize
      end

      def run_formatting(uri, document)
        source = document.source
        
        sorted_source = sort_links(source)
        add_missing_error_contracts(sorted_source)
      rescue => e
        $stderr.puts("error in ree_formatter: #{e.message} : #{e.backtrace.first}")
      end

      def run_diagnostic(uri, document)
        detect_missing_error_locales(uri, document)
        # [
        #   RubyLsp::Interface::Diagnostic.new(
        #     message: "Hello from custom formatter",
        #     source: "Custom formatter",
        #     severity: RubyLsp::Constant::DiagnosticSeverity::ERROR,
        #     range: RubyLsp::Interface::Range.new(
        #       start: RubyLsp::Interface::Position.new(line: 0, character: 0),
        #       end: RubyLsp::Interface::Position.new(line: 2, character: 3),
        #     ),
        #   ),
        # ]
      rescue => e
        $stderr.puts("error in ree_formatter_diagnostic: #{e.message} : #{e.backtrace.first}")
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

        parsed_doc.doc_instance_methods.select(&:has_contract?).each do |doc_instance_method|
          doc_instance_method.parse_nested_local_methods(parsed_doc.doc_instance_methods)

          raised_errors = doc_instance_method.raised_errors_nested(source, parsed_doc.error_definitions)
          throws_errors = doc_instance_method.throws_errors

          missed_errors = raised_errors - throws_errors
          source = add_missed_errors(source, doc_instance_method, missed_errors)
        end

        source
      end

      def add_missed_errors(source, doc_instance_method, missed_errors)
        return source if missed_errors.size == 0

        source_lines = source.lines

        if doc_instance_method.has_throw_section?
          position = doc_instance_method.throw_arguments_end_position
          line = doc_instance_method.throw_arguments_end_line

          source_lines[line] = source_lines[line][0..position] + ", #{missed_errors.join(', ')})\n"
        else
          position = doc_instance_method.contract_node_end_position
          line = doc_instance_method.contract_node_end_line

          source_lines[line] = source_lines[line][0..position] + ".throws(#{missed_errors.join(', ')})\n"
        end


        source_lines.join()
      end

      def detect_missing_error_locales(uri, document)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(document.source)

        locales_folder = package_locales_folder_path(uri.path)
        return [] unless File.directory?(locales_folder)

        result = []
        key_paths = []
        parsed_doc.parse_error_definitions
        parsed_doc.error_definitions.each do |error_definition|
          key_path = if error_definition.value.arguments.arguments.size > 1
            error_definition.value.arguments.arguments[1].unescaped
          else
            mod = underscore(parsed_doc.module_name)
            "#{mod}.errors.#{error_definition.value.arguments.arguments[0].unescaped}"
          end

          key_paths << key_path
        end

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          key_paths.each do |key_path|
            value = find_locale_value(locale_file, key_path)
            unless value
              loc_key = File.basename(locale_file, '.yml')

              # TODO correct error range
              result <<RubyLsp::Interface::Diagnostic.new(
                message: "Missing locale #{loc_key}: #{key_path}",
                source: "Ree formatter",
                severity: RubyLsp::Constant::DiagnosticSeverity::ERROR,
                range: RubyLsp::Interface::Range.new( 
                  start: RubyLsp::Interface::Position.new(line: 0, character: 0),
                  end: RubyLsp::Interface::Position.new(line: 0, character: 0),
                ),
              )
            end
          end
        end

        result
      end
    end
  end
end
