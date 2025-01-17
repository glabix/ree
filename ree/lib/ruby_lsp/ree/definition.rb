module RubyLsp
  module Ree
    class Definition
      include Requests::Support::Common

      def initialize(response_builder, node_context, index, dispatcher)
        @response_builder = response_builder
        @node_context = node_context
        @nesting = node_context.nesting
        @index = index

        # dispatcher.register(self, :on_call_node_enter, :on_symbol_node_enter, :on_string_node_enter)
        dispatcher.register(self, :on_call_node_enter)
      end

      def on_call_node_enter(node)
        message = node.message
        $stderr.puts("definition on_call_node_enter #{message}")

        return unless message

        method = @index[message].detect{ !_1.location.nil? }

        $stderr.puts method.inspect

        return unless method

        @response_builder << Interface::Location.new(
          uri: method.uri.to_s,
          range: Interface::Range.new(
            start: Interface::Position.new(line: 0, character: 0),
            end: Interface::Position.new(line: 0, character: 0),
          ),
        )

        nil
      end
    end
  end
end