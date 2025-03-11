require_relative "../ree_object_finder"
require_relative "../parsing/parsed_document_builder"
require_relative "../parsing/parsed_link_node"
require_relative "../utils/ree_lsp_utils"
require 'yaml'

module RubyLsp
  module Ree
    class HoverHandler
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      def initialize(index, node_context)
        @index = index
        @node_context = node_context
        @finder = ReeObjectFinder.new(@index)
        @root_node = @node_context.instance_variable_get(:@nesting_nodes).first
      end

      def get_ree_object_hover_items(node)
        ree_object = @finder.find_object(node.name.to_s)

        return [] unless ree_object

        documentation = get_object_documentation(ree_object)

        [documentation]
      end

      def get_linked_object_hover_items(node)
        parent_node = @node_context.parent
        return [] unless parent_node.name == :link

        ree_object = @finder.find_object(node.unescaped)

        return [] unless ree_object

        documentation = get_object_documentation(ree_object)

        [documentation]
      end

      def get_object_documentation(ree_object)
        <<~DOC
        \`\`\`ruby
        #{ree_object.name}#{get_detail_string(ree_object)}
        \`\`\`
        ---
        #{@finder.object_documentation(ree_object)}

        [#{path_from_package_folder(ree_object.uri)}](#{ree_object.uri})
        DOC
      end

      def get_detail_string(ree_object)
        return '' if ree_object.signatures.size == 0

        "(#{get_parameters_string(ree_object.signatures.first)})"
      end

      def get_parameters_string(signature)
        return '' unless signature

        signature.parameters.map(&:decorated_name).join(', ')
      end

      def get_error_code_hover_items(node)
        uri = get_uri_from_object()

        locales_folder = package_locales_folder_path(uri.path)

        $stderr.puts(locales_folder)
        return [] unless File.directory?(locales_folder)

        result = []

        key_path = if @node_context.parent.arguments.arguments.size > 1
          @node_context.parent.arguments.arguments[1].unescaped
        else
          parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, uri)

          mod = underscore(parsed_doc.module_name)
          "#{mod}.errors.#{node.unescaped}"
        end

        $stderr.puts(key_path)


        documentation = ''

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          value = find_locale_value(locale_file, key_path)
          $stderr.puts(value)

          if value
            loc_key = File.basename(locale_file, '.yml')
            documentation += "#{loc_key}: #{value}\n\n"
          end
        end

        [documentation]
      end

      def find_locale_value(file_path, key_path)
        loc_yaml = YAML.load_file(file_path)
        loc_key = File.basename(file_path, '.yml')
        key_parts = [loc_key] + key_path.split('.')

        loc_yaml.dig(*key_parts)
      end

      def get_uri_from_object()
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, nil)
        obj = parsed_doc.links_container_node_name

        $stderr.puts(obj.inspect)
        ree_obj = @finder.find_object(obj)
        $stderr.puts(ree_obj.uri.inspect)

        ree_obj.uri
      end

      def underscore(str)
        str.gsub(/::/, '/')
           .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
           .gsub(/([a-z\d])([A-Z])/,'\1_\2')
           .tr("-", "_")
           .downcase
      end
    end
  end
end