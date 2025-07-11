require_relative "../utils/ree_lsp_utils"
require_relative "../ree_object_finder"
require_relative '../completion/completion_items_mapper'
require_relative "../ree_context"

module RubyLsp
  module Ree
    class CompletionHandler
      include Requests::Support::Common
      include RubyLsp::Ree::ReeLspUtils

      RECEIVER_OBJECT_TYPES = [:enum, :dao, :bean, :async_bean]
      CANDIDATES_LIMIT = 100

      def initialize(index, uri, node_context)
        @index = index
        @uri = uri
        @node_context = node_context
        @root_node = @node_context.instance_variable_get(:@nesting_nodes).first
        @finder = ReeObjectFinder.new(@index)
        @mapper = RubyLsp::Ree::CompletionItemsMapper.new(@index)
        @ree_context = RubyLsp::Ree::ReeContext.new(node_context)
      end

      def get_ree_receiver(receiver_node)
        return if !receiver_node || !receiver_node.is_a?(Prism::CallNode)
      
        @finder.find_objects_by_types(receiver_node.name.to_s, RECEIVER_OBJECT_TYPES).first
      end

      def get_ree_object_methods_completions_items(ree_receiver, receiver_node, node)
        location = receiver_node.location

        case @finder.object_type(ree_receiver)
        when :enum
          get_enum_values_completion_items(ree_receiver, location, node)
        when :bean, :async_bean
          get_bean_methods_completion_items(ree_receiver, location, node)
        when :dao
          get_dao_filters_completion_items(ree_receiver, location, node)
        else
          []
        end
      end

      def get_bean_methods_completion_items(bean_obj, location, node)
        bean_node = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(bean_obj.uri, :bean)
        @mapper.map_ree_object_methods(bean_node.bean_methods, location, node, "method")
      end

      def get_dao_filters_completion_items(dao_obj, location, node)
        dao_node = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(dao_obj.uri, :dao)
        @mapper.map_ree_object_methods(dao_node.filters, location, node, "filter")
      end

      def get_enum_values_completion_items(enum_obj, location, node)
        enum_node = RubyLsp::Ree::ParsedDocumentBuilder.build_from_uri(enum_obj.uri, :enum)
        class_name = enum_node.full_class_name
        @mapper.map_ree_object_methods(enum_node.values, location, node, "from: #{class_name}")
      end

      def get_class_name_completion_items(node)
        node_name = node.name.to_s
        class_name_objects = @finder.search_class_objects(node_name)
        
        return [] if class_name_objects.size == 0

        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, @uri)

        @mapper.map_class_name_objects(class_name_objects.take(CANDIDATES_LIMIT), node, parsed_doc,  @ree_context)
      end

      def get_ree_objects_completions_items(node)
        ree_objects = @finder.search_objects(node.name.to_s, CANDIDATES_LIMIT)

        return [] if ree_objects.size == 0
  
        parsed_doc = RubyLsp::Ree::ParsedDocumentBuilder.build_from_ast(@root_node, @uri)

        @mapper.map_ree_objects(ree_objects, node, parsed_doc)
      end
    end
  end
end