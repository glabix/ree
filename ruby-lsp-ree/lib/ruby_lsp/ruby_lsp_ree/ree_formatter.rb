require_relative 'formatters/sort_links_formatter'
require_relative 'formatters/missing_error_definitions_formatter'
require_relative 'formatters/missing_error_contracts_formatter'

module RubyLsp
  module Ree
    class ReeFormatter
      include RubyLsp::Requests::Support::Formatter
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      def run_formatting(uri, document)
        source = document.source

        formatters = [
          RubyLsp::Ree::SortLinksFormatter,
          RubyLsp::Ree::MissingErrorDefinitionsFormatter,
          RubyLsp::Ree::MissingErrorContractsFormatter
        ]

        formatters.reduce(source){ |s, formatter| formatter.call(s) }
      rescue => e
        $stderr.puts("error in ree_formatter: #{e.message} : #{e.backtrace.first}")
      end

      def run_diagnostic(uri, document)
        detect_missing_error_locales(uri, document)
      rescue => e
        $stderr.puts("error in ree_formatter_diagnostic: #{e.message} : #{e.backtrace.first}")
      end

      private

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
