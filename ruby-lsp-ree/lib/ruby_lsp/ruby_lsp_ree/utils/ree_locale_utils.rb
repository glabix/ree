require 'yaml'

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

      def find_locale_key_line(file_path, key_path)
        loc_key = File.basename(file_path, '.yml')

        key_parts = [loc_key] + key_path.split('.')

        current_key_index = 0
        current_key = key_parts[current_key_index]
        regex = /^\s*#{Regexp.escape(current_key)}:/

        File.open(file_path, 'r:UTF-8').each_with_index do |line, line_index|
          if line.match?(regex)
            current_key_index += 1
            current_key = key_parts[current_key_index]
            return line_index unless current_key

            regex = /^\s*#{Regexp.escape(current_key)}:/
          end
        end

        0
      end
    end
  end
end