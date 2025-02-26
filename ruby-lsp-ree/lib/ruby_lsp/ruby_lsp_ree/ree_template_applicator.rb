module RubyLsp
  module Ree
    class ReeTemplateApplicator
      def initialize
        # fetch templates folder
      end

      def apply(changes)
        uri = changes.uri
        template_type = get_template_type_from_uri(uri)
        return unless template_type

        template_str = fetch_template(template_type)
        template_info = fetch_template_info(uri, template_type)

        replace_placeholders(template_type, template_str, template_info)
      end

      def get_template_type_from_uri(uri)
        uri_parts = File.dirname(uri).split('/')

        uri_parts.reverse_order.detect{ @template_types.include?(_1) }
      end

      def fetch_template(template_type)
        # read from template file
      end
    end
  end
end