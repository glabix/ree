require 'yaml'
require_relative 'yaml_file_parser'

module RubyLsp
  module Ree
    module ReeLocaleUtils
      def package_locales_folder_path(uri)
        uri_parts = uri.to_s.chomp(File.extname(uri.to_s)).split('/')

        package_folder_index = uri_parts.index('package')
        return unless package_folder_index

        path_parts = uri_parts.take(package_folder_index+2) + ['locales']
        path_parts.join('/')
      end
      
      def find_locale_value(file_path, key_path)
        loc_yaml = YAML.load_file(file_path)
        loc_key = File.basename(file_path, '.yml')
        key_parts = [loc_key] + key_path.split('.')

        loc_yaml.dig(*key_parts)
      end

      def find_locale_key_location(file_path, key_path)
        loc_key = File.basename(file_path, '.yml')

        key_parts = [loc_key] + key_path.split('.')
        parsed_yaml = RubyLsp::Ree::YamlFileParser.parse(file_path)
        key_location = parsed_yaml.dig(*key_parts)

        if key_location
          OpenStruct.new(line: key_location.line, column: key_location.column)
        else
          OpenStruct.new(line: 0, column: 0)
        end
      end
    end
  end
end
