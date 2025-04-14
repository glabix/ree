require_relative 'base_formatter'

module RubyLsp
  module Ree
    class MissingErrorLocalesFormatter < BaseFormatter
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      MISSING_LOCALE_PLACEHOLDER = '_MISSING_LOCALE_'

      def call(source, uri)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_source(source)
        return source if !parsed_doc || !parsed_doc.has_root_class?

        locales_folder = package_locales_folder_path(get_uri_path(uri))
        return source if !locales_folder || !File.directory?(locales_folder)

        file_name = File.basename(uri.to_s, '.rb')

        result = []
        key_paths = []
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

          key_paths << key_path_entries
        end

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          key_paths.each do |key_path_entries|
            value = key_path_entries.map{ find_locale_value(locale_file, _1) }.compact.first
            unless value
              key_path = key_path_entries.last
              loc_key = File.basename(locale_file, '.yml')

              add_locale_placeholder(locale_file, key_path)    
              send_message(locale_file, key_path)      
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
        last_found_key = nil
        current_node = YamlFileParser.parse_with_key_coordinates(file_path)

        key_parts.each_with_index do |key_part, index|
          found_key, next_node = YamlFileParser.find_key_in_node(current_node, key_part)

          break unless found_key

          current_node = next_node
          last_found_index = index
          last_found_key = found_key
        end

        missed_key_parts = key_parts[last_found_index+1..-1]

        identation = last_found_key.column
        adding_string = ''
        missed_key_parts.each_with_index do |key_part, index|
          identation += 2
          if index == missed_key_parts.size - 1
            adding_string += "\s" * identation + "#{key_part}: #{MISSING_LOCALE_PLACEHOLDER}\n"
          else
            adding_string += "\s" * identation + "#{key_part}:\n"
          end
        end

        lines = File.read(file_path).lines
        lines[last_found_key.line] += adding_string
        
        new_source = lines.join.force_encoding("utf-8")
        File.open(file_path, 'wb:UTF-8'){|f|
          f.write(new_source)
        }
        
        new_source
      end

      def send_message(locale_file, key_path)   
        loc_key = File.basename(locale_file, '.yml')

        message = "Missing locale #{loc_key}: #{key_path}"
        @message_queue << RubyLsp::Notification.window_show_message(message, type: Constant::MessageType::ERROR)
      end
    end
  end
end