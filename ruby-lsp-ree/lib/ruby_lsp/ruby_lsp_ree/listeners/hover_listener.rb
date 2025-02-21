require_relative "../ree_object_finder"
require_relative "../parsing/parsed_document_builder"
require_relative "../parsing/parsed_link_node"
require_relative "../utils/ree_lsp_utils"

module RubyLsp
  module Ree
    class HoverListener
      include RubyLsp::Ree::ReeLspUtils

      def initialize(response_builder, node_context, index, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @finder = ReeObjectFinder.new(index)

        dispatcher.register(self, :on_call_node_enter)
        dispatcher.register(self, :on_constant_read_node_enter)
      end

      def on_constant_read_node_enter(node)
        # ree_object = @finder.search_classes(node.name.to_s).first

        # $stderr.puts("ree_object #{ree_object.inspect}")

        # return unless ree_object

        # $stderr.puts("ree_object comm #{ree_object.comments.to_s}")

        # @response_builder.push(ree_object.comments.to_s, category: :documentation)
      end

      def on_call_node_enter(node)
        ree_object = @finder.find_object(node.name.to_s)

        return unless ree_object

        documentation =  <<~DOC
        Ree object, type: :#{@finder.object_type(ree_object)}

        usage: #{node.name.to_s}#{get_detail_string(ree_object)}
        
        package: #{package_name_from_uri(ree_object.uri)}

        file: #{path_from_package_folder(ree_object.uri)}
        DOC

        $stderr.puts(documentation)

        @response_builder.push(documentation, category: :documentation)
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
