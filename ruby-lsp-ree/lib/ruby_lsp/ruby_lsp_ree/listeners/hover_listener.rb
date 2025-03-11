require_relative "../handlers/hover_handler"

module RubyLsp
  module Ree
    class HoverListener
      include RubyLsp::Ree::ReeLspUtils

      def initialize(response_builder, node_context, index, dispatcher)
        @response_builder = response_builder
        @handler = RubyLsp::Ree::HoverHandler.new(index, node_context)
        @ree_context = RubyLsp::Ree::ReeContext.new(node_context)

        dispatcher.register(
          self, 
          :on_call_node_enter,
          :on_symbol_node_enter,
          :on_constant_read_node_enter
        )
      end

      def on_constant_read_node_enter(node)
        # ree_object = @finder.search_classes(node.name.to_s).first

        # $stderr.puts("ree_object #{ree_object.inspect}")

        # return unless ree_object

        # $stderr.puts("ree_object comm #{ree_object.comments.to_s}")

        # @response_builder.push(ree_object.comments.to_s, category: :documentation)
      end

      def on_call_node_enter(node)
        hover_items = @handler.get_ree_object_hover_items(node)
        put_items_into_response(hover_items)
      rescue => e
        $stderr.puts("error in hover listener(on_call_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def on_symbol_node_enter(node)
        hover_items = if @ree_context.is_error_definition?
          @handler.get_error_code_hover_items(node)
        else
          @handler.get_linked_object_hover_items(node)
        end

        put_items_into_response(hover_items)
      rescue => e
        $stderr.puts("error in hover listener(on_symbol_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def put_items_into_response(items)
        items.each do |item|
          @response_builder.push(item, category: :documentation)
        end
      end
    end
  end
end
