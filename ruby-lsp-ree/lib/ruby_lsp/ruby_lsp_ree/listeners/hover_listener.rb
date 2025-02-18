require_relative "../ree_object_finder"
require_relative "../parsing/parsed_document_builder"
require_relative "../parsing/parsed_link_node"

module RubyLsp
  module Ree
    class HoverListener
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

        $stderr.puts("ree_object #{ree_object.inspect}")

        return unless ree_object

        $stderr.puts("ree_object comm #{ree_object.comments.to_s}")

        @response_builder.push(ree_object.comments.to_s, category: :documentation)
      end
    end
  end
end
