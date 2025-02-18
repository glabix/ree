module RubyLsp
  module Ree
    class HoverListener
      def initialize(response_builder, node_context, index, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @index = index

        dispatcher.register(self, :on_call_node_enter)
        dispatcher.register(self, :on_constant_read_node_enter)
      end

      def on_constant_read_node_enter(node)
        $stderr.puts("on_constant_read_node_enter hover")
      end

      def on_call_node_enter(node)
        $stderr.puts("on_call_node_enter hover")
      end
    end
  end
end
