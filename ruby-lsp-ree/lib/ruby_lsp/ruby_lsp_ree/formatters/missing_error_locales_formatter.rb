require_relative 'base_formatter'

module RubyLsp
  module Ree
    class MissingErrorLocalesFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      def call(source, uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)

        locales_folder = package_locales_folder_path(URI.parse(uri).path)
        return source if !locales_folder || !File.directory?(locales_folder)

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

              add_locale_placeholder(locale_file, key_path)          
            end
          end
        end

        source
      end

      private 
      
      def add_locale_placeholder(file_path, key_path)
        loc_key = File.basename(file_path, '.yml')
        key_parts = [loc_key] + key_path.split('.')

        last_found_index = 0
        current_node = yaml_with_line_numbers
        key_parts.each_with_index do |key_part, index|
          next_node = find_key_in_node(current_node)

          break unless next_node

          current_node = next_node
          last_found_index = index
        end

        pp key_parts
        pp last_found_index
        pp current_node
      end
    end
  end
end