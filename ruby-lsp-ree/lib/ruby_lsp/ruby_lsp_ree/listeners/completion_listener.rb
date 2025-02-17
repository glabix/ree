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
        if receiver_is_enum?(node)
          return enum_value_completion(node)
        end

        if receiver_is_dao?(node)
          return dao_filter_completion(node)
        end

        if receiver_is_bean?(node)
          return bean_method_completion(node)
        end

        return if node.receiver
        return if node.name.to_s.size < CHARS_COUNT

        ree_objects = ReeObjectFinder.search_objects(@index, node.name.to_s, CANDIDATES_LIMIT)

        return if ree_objects.size == 0

        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@node_context.parent, @uri)

        completion_items = get_ree_objects_completions_items(ree_objects, parsed_doc, node)
        put_items_into_response(completion_items)
      end

      def receiver_is_enum?(node)
        node.receiver && node.receiver.is_a?(Prism::CallNode) && ReeObjectFinder.find_enum(@index, node.receiver.name.to_s)
      end

      def receiver_is_dao?(node)
        node.receiver && node.receiver.is_a?(Prism::CallNode) && ReeObjectFinder.find_dao(@index, node.receiver.name.to_s)
      end

      def receiver_is_bean?(node)
        node.receiver && node.receiver.is_a?(Prism::CallNode) && ReeObjectFinder.find_bean(@index, node.receiver.name.to_s)
      end

      def enum_value_completion(node)
        enum_obj = ReeObjectFinder.find_enum(@index, node.receiver.name.to_s)
        location = node.receiver.location
        
        completion_items = get_enum_values_completion_items(enum_obj, location)
        put_items_into_response(completion_items)
      end

      def dao_filter_completion(node)
        dao_obj = ReeObjectFinder.find_dao(@index, node.receiver.name.to_s)
        location = node.receiver.location

        completion_items = get_dao_filters_completion_items(dao_obj, location)
        put_items_into_response(completion_items)
      end

      def bean_method_completion(node)
        bean_obj = ReeObjectFinder.find_bean(@index, node.receiver.name.to_s)
        location = node.receiver.location

        completion_items = get_bean_methods_completion_items(bean_obj, location)

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
