module RubyLsp
  module Ree
    class ReeTemplateApplicator
      TEMPLATES_FOLDER = '.vscode-ree/templates'
      DEFAULT_TEMPLATE_FILENAME = 'default.rb'

      def initialize
        @template_types =  Dir.entries(TEMPLATES_FOLDER).select {|entry| File.directory? File.join(TEMPLATES_FOLDER,entry) and !(entry =='.' || entry == '..') }
      end

      def apply(change_item)
        uri = change_item[:uri]
        path = URI.parse(uri).path

        file_content = File.read(path)
        return if file_content.size > 0
        
        template_type = get_template_type_from_uri(uri)

        $stderr.puts("template type #{template_type}")
        return unless template_type

        template_str = fetch_template(template_type)
        $stderr.puts("template_str #{template_str}")

        template_info = fetch_template_info(uri, template_type)

        template_content = replace_placeholders(template_type, template_str, template_info)

        path = URI.parse(uri).path
        $stderr.puts("template_url #{path}")

        File.write(path, template_content)
      end

      def get_template_type_from_uri(uri)
        uri_parts = File.dirname(uri).split('/')

        uri_parts.reverse.detect{ @template_types.include?(_1) }
      end

      def fetch_template(template_type)
        File.read(File.join(TEMPLATES_FOLDER, template_type, DEFAULT_TEMPLATE_FILENAME))
      end

      def fetch_template_info(uri, template_type)
        {}
      end

      def replace_placeholders(template_type, template_str, template_info)
        template_str
      end
    end
  end
end