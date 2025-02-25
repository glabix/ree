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

        documentation =  <<~DOC
        Ree object, type: :#{@finder.object_type(ree_object)}

        usage: #{node.name.to_s}#{get_detail_string(ree_object)}
        
        package: #{package_name_from_uri(ree_object.uri)}

        file: #{path_from_package_folder(ree_object.uri)}
        DOC

        [documentation]
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