require "ruby_lsp/addon"
require_relative "basic_listener"

module RubyLsp
  module Ree
    class Addon < ::RubyLsp::Addon
      def activate(global_state, message_queue)
        $stderr.puts "in activate"

        @message_queue = message_queue
      end

      def deactivate
      end

      def name
        "Ree Addon"
      end

      def create_hover_listener(response_builder, node_context, dispatcher)
        $stderr.puts "in create_hover_listener"

        BasicListener.new(dispatcher, response_builder)
      end
    end
  end
end