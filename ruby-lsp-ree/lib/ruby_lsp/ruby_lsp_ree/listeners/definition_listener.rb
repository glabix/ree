require_relative "../handlers/definition_handler"
require_relative "../ree_context"

module RubyLsp
  module Ree
    class DefinitionListener
      include Requests::Support::Common

      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @handler = RubyLsp::Ree::DefinitionHandler.new(index, uri, node_context)
        @ree_context = RubyLsp::Ree::ReeContext.new(node_context)

        dispatcher.register(
          self, 
          :on_call_node_enter, 
          :on_symbol_node_enter, 
          :on_string_node_enter, 
          :on_constant_read_node_enter
        )
      end

      def on_constant_read_node_enter(node)
        definition_items = @handler.get_constant_definition_items(node)
        put_items_into_response(definition_items)
      rescue => e
        $stderr.puts("error in definition listener(on_constant_read_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def on_call_node_enter(node)
        return unless node.message

        if node.receiver
          # ruby lsp handles such cases itself
          return
        else
          definition_items = @handler.get_ree_objects_definition_items(node)
          put_items_into_response(definition_items)
        end
      rescue => e
        $stderr.puts("error in definition listener(on_call_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def on_symbol_node_enter(node)
        definition_items = if @ree_context.is_error_definition?
          @handler.get_error_code_definition_items(node)
        elsif @ree_context.is_link_object?
          if @ree_context.is_package_argument?
            @handler.get_package_definition_items(node)
          else
            @handler.get_linked_object_definition_items(node)
          end
        else
          @handler.get_routes_definition_items(node)
        end
        
        put_items_into_response(definition_items)
      rescue => e
        $stderr.puts("error in definition listener(on_symbol_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def on_string_node_enter(node)
        definition_items = if @ree_context.is_error_definition?
          @handler.get_error_locales_definition_items(node)
        else
          @handler.get_linked_filepath_definition_items(node)
        end

        put_items_into_response(definition_items)
      rescue => e
        $stderr.puts("error in definition listener(on_string_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def put_items_into_response(items)
        items.each do |item|
          @response_builder << item
        end
      end
    end
  end
end