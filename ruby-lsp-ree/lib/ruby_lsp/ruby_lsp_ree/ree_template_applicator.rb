module RubyLsp
  module Ree
    class ReeTemplateApplicator
      include RubyLsp::Ree::ReeLspUtils

      TEMPLATES_FOLDER = '.vscode-ree/templates'
      DEFAULT_TEMPLATE_FILENAME = 'default.rb'

      def initialize
        return unless template_dir_exists?

        @template_types = Dir
          .entries(TEMPLATES_FOLDER)
          .select{ |entry| 
            File.directory? File.join(TEMPLATES_FOLDER,entry) and !(entry =='.' || entry == '..')
          }
      end

      def template_dir_exists?
        File.exist?(TEMPLATES_FOLDER)
      end

      def apply(change_item)
        uri = change_item[:uri]
        path = URI.parse(uri).path

        return if path.end_with?('_spec.rb') # skip spec templates for now

        file_content = File.read(path)
        return if file_content.size > 0

        template_type = get_template_type_from_uri(uri)
        return unless template_type

        template_str = fetch_template(template_type)

        template_info = fetch_template_info(uri)

        template_content = replace_placeholders(template_str, template_info)

        File.write(path, template_content)
      end

      def get_template_type_from_uri(uri)
        uri_parts = File.dirname(uri).split('/')

        uri_parts.reverse.detect{ @template_types.include?(_1) }
      end

      def fetch_template(template_type)
        File.read(File.join(TEMPLATES_FOLDER, template_type, DEFAULT_TEMPLATE_FILENAME))
      end

      def fetch_template_info(uri)
        object_name = File.basename(uri, '.rb')
        object_class = object_name.split('_').collect(&:capitalize).join
        package_name = package_name_from_uri(uri)
        package_class = package_name.split('_').collect(&:capitalize).join
        
        {
          'PACKAGE_MODULE' => package_class,
          'PACKAGE_NAME' => package_name,
          'OBJECT_CLASS' => object_class,
          'OBJECT_NAME' => object_name,
        }
      end

      def replace_placeholders(template_str, template_info)
        template_info.each do |k,v|
          template_str.gsub!(k, v)
        end

        template_str
      end
    end
  end
end