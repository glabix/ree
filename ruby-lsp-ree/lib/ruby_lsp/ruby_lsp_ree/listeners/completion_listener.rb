require_relative "../handlers/completion_handler"

module RubyLsp
  module Ree
    class CompletionListener
      include Requests::Support::Common

      CHARS_COUNT = 1
      
      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @handler = RubyLsp::Ree::CompletionHandler.new(index, uri, node_context)

        dispatcher.register(self, :on_call_node_enter)
        dispatcher.register(self, :on_constant_read_node_enter)
      end

      def on_constant_read_node_enter(node)
        node_name = node.name.to_s
        return if node_name.size < CHARS_COUNT

        completion_items = @handler.get_class_name_completion_items(node)
        put_items_into_response(completion_items)
      rescue => e
        $stderr.puts("error in completion listener(on_constant_read_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def on_call_node_enter(node)
        completion_items = []
        ree_receiver = @handler.get_ree_receiver(node.receiver)

        if ree_receiver
          completion_items = @handler.get_ree_object_methods_completions_items(ree_receiver, node.receiver, node)
        else
          return if node.receiver
          return if node.name.to_s.size < CHARS_COUNT
  
          completion_items = @handler.get_ree_objects_completions_items(node)
        end
        
        put_items_into_response(completion_items)
      rescue => e
        $stderr.puts("error in completion listener(on_call_node_enter): #{e.message} : #{e.backtrace.first}")
      end

      def put_items_into_response(items)
        items.each do |item|
          @response_builder << item
        end
      end
    end
  end
end
