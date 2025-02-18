require "ruby_lsp/addon"
require_relative "listeners/definition_listener"
require_relative "listeners/completion_listener"
require_relative "listeners/hover_listener"
require_relative "ree_indexing_enhancement"
require_relative "utils/ree_lsp_utils"
require_relative "ree_formatter"
require_relative "parsing/parsed_document_builder"

module RubyLsp
  module Ree
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        @global_state = global_state
        @message_queue = message_queue

        global_state.register_formatter("ree_formatter", RubyLsp::Ree::ReeFormatter.new)
      end

      def deactivate
      end

      def name
        "Ree Addon"
      end

      def create_definition_listener(response_builder, uri, node_context, dispatcher)
        index = @global_state.index
        RubyLsp::Ree::DefinitionListener.new(response_builder, node_context, index, dispatcher, uri)
      end

      def create_completion_listener(response_builder, node_context, dispatcher, uri)
        index = @global_state.index
        RubyLsp::Ree::CompletionListener.new(response_builder, node_context, index, dispatcher, uri)
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        index = @global_state.index
        RubyLsp::Ree::HoverListener.new(response_builder, node_context, index, dispatcher)
      end
    end
  end
end