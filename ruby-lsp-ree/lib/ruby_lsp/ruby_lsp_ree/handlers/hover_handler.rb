require_relative "../ree_object_finder"
require_relative "../parsing/parsed_document_builder"
require_relative "../parsing/parsed_link_node"
require_relative "../utils/ree_lsp_utils"
require_relative "../utils/ree_locale_utils"

module RubyLsp
  module Ree
    class HoverHandler
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::ReeLocaleUtils

      MISSING_LOCALE_PLACEHOLDER = '_MISSING_LOCALE_'

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

      def get_error_locales_hover_items(node)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, nil)
        uri = get_uri_from_object(parsed_doc)

        locales_folder = package_locales_folder_path(uri.path)
        return [] unless File.directory?(locales_folder)

        result = []
        key_path = node.unescaped

        documentation = ''

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          value = find_locale_value(locale_file, key_path)
          loc_key = File.basename(locale_file, '.yml')

          if value
            if value == MISSING_LOCALE_PLACEHOLDER
              value_location = find_locale_key_location(locale_file, key_path)
              file_uri = "file://#{locale_file}##{value_location.line+1}"
              documentation += "#{loc_key}: [#{value}](#{file_uri})\n\n"
            else
              documentation += "#{loc_key}: #{value}\n\n"
            end
          else
            documentation += "#{loc_key}: [MISSING TRANSLATION](#{locale_file})\n\n"
          end
        end

        [documentation]
      end

      def get_error_code_hover_items(node)
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, nil)
        uri = get_uri_from_object(parsed_doc)

        locales_folder = package_locales_folder_path(uri.path)
        return [] unless File.directory?(locales_folder)

        result = []

        key_path = if @node_context.parent.arguments.arguments.size > 1
          @node_context.parent.arguments.arguments[1].unescaped
        else
          mod = underscore(parsed_doc.module_name)
          "#{mod}.errors.#{node.unescaped}"
        end

        documentation = ''

        Dir.glob(File.join(locales_folder, '**/*.yml')).each do |locale_file|
          value = find_locale_value(locale_file, key_path)

          loc_key = File.basename(locale_file, '.yml')

          if value
            if value == MISSING_LOCALE_PLACEHOLDER
              value_location = find_locale_key_location(locale_file, key_path)
              file_uri = "#{locale_file}" # TODO add line to uri :#{value_location.line+1}:#{value_location.column}"
              documentation += "#{loc_key}: [#{value}](#{file_uri})\n\n"
            else
              documentation += "#{loc_key}: #{value}\n\n"
            end
          else
            documentation += "#{loc_key}: [MISSING TRANSLATION](#{locale_file})\n\n"
          end
        end

        [documentation]
      end

      def get_uri_from_object(parsed_doc)
        obj = parsed_doc.links_container_node_name

        ree_obj = @finder.find_object(obj)
        ree_obj.uri
      end
    end
  end
end