require_relative "../ree_object_finder"
require_relative "../parsing/parsed_document_builder"
require_relative "../parsing/parsed_link_node"
require_relative "../utils/ree_lsp_utils"

module RubyLsp
  module Ree
    class HoverHandler
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      def initialize(index, node_context)
        @index = index
        @node_context = node_context
        @finder = ReeObjectFinder.new(@index)
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
    end
  end
end