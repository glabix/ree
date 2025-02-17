require_relative "../utils/ree_lsp_utils"
require_relative "../utils/completion_utils"
require_relative "../ree_object_finder"

module RubyLsp
  module Ree
    class CompletionListener
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils
      include RubyLsp::Ree::CompletionUtils

      CHARS_COUNT = 1
      CANDIDATES_LIMIT = 100
      
      def initialize(response_builder, node_context, index, dispatcher, uri)
        @response_builder = response_builder
        @index = index
        @uri = uri
        @node_context = node_context

        dispatcher.register(self, :on_call_node_enter)
        dispatcher.register(self, :on_constant_read_node_enter)
      end

      def on_constant_read_node_enter(node)
        node_name = node.name.to_s
        return if node_name.size < CHARS_COUNT

        completion_items = get_class_name_completion_items(node, @node_context, @index, @uri, CANDIDATES_LIMIT)
        put_items_into_response(completion_items)
      end

      def on_call_node_enter(node)
        completion_items = []
        ree_receiver = get_ree_receiver(node.receiver, @index)

        if ree_receiver
          completion_items = get_ree_object_methods_completions_items(ree_receiver, node.receiver, node)
        else
          return if node.receiver
          return if node.name.to_s.size < CHARS_COUNT

          ree_objects = ReeObjectFinder.search_objects(@index, node.name.to_s, CANDIDATES_LIMIT)

          return if ree_objects.size == 0
  
          parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@node_context.parent, @uri)
  
          completion_items = get_ree_objects_completions_items(ree_objects, parsed_doc, node)
        end
        
        put_items_into_response(completion_items)
      end

      def put_items_into_response(items)
        items.each do |item|
          @response_builder << item
        end
      end
    end
  end
end
