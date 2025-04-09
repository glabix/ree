require_relative 'formatters/sort_links_formatter'
require_relative 'formatters/missing_error_definitions_formatter'
require_relative 'formatters/missing_error_contracts_formatter'
require_relative 'formatters/missing_error_locales_formatter'
require_relative 'formatters/unused_links_formatter'

module RubyLsp
  module Ree
    class ReeFormatter
      include RubyLsp::Requests::Support::Formatter
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      MISSING_LOCALE_PLACEHOLDER = '_MISSING_LOCALE_'

      def initialize(message_queue)
        @message_queue = message_queue
      end

      def run_formatting(uri, document)
        source = document.source

        formatters = [
          RubyLsp::Ree::SortLinksFormatter,
          RubyLsp::Ree::MissingErrorDefinitionsFormatter,
          RubyLsp::Ree::MissingErrorContractsFormatter,
          RubyLsp::Ree::MissingErrorLocalesFormatter,
          RubyLsp::Ree::UnusedLinksFormatter,
        ]

        formatters.reduce(source){ |s, formatter| formatter.call(s, uri, @message_queue) }
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
        return [] if !locales_folder || !File.directory?(locales_folder)

        result = []
        error_keys = []
        file_name = File.basename(uri.to_s, '.rb')

        parsed_doc.parse_error_definitions
        parsed_doc.error_definitions.each do |error_definition|
          key_path_entries = if error_definition.value.arguments.arguments.size > 1
            [error_definition.value.arguments.arguments[1].unescaped]
          else
            mod = underscore(parsed_doc.module_name)
            [
              "#{mod}.errors.#{error_definition.value.arguments.arguments[0].unescaped}",
              "#{mod}.errors.#{file_name}.#{error_definition.value.arguments.arguments[0].unescaped}"
            ]
          end

          error_keys << [key_path_entries, error_definition]
        end

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          error_keys.each do |error_key|
            key_path_entries = error_key[0]
            value = key_path_entries.map{ find_locale_value(locale_file, _1) }.compact.first

            if !value || value == MISSING_LOCALE_PLACEHOLDER
              loc_key = File.basename(locale_file, '.yml')
              error_definition = error_key[1]

              result << RubyLsp::Interface::Diagnostic.new(
                message: "Missing locale #{loc_key}: #{key_path_entries[0]} or #{key_path_entries[1]} ",
                source: "Ree formatter",
                severity: RubyLsp::Constant::DiagnosticSeverity::ERROR,
                range: RubyLsp::Interface::Range.new( 
                  start: RubyLsp::Interface::Position.new(line: error_definition.location.start_line-1, character: error_definition.name_loc.start_column),
                  end: RubyLsp::Interface::Position.new(line: error_definition.location.start_line-1, character: error_definition.name_loc.end_column),
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
