require 'prism'
require_relative "ree_constants"

module RubyLsp
  module Ree
    class ReeContext
      include RubyLsp::Ree::ReeConstants

      def initialize(node_context)
        @node_context = node_context
      end

      def is_error_definition?
        return false if !@node_context || !@node_context.parent || !@node_context.parent.is_a?(Prism::CallNode)
        
        ERROR_DEFINITION_NAMES.include?(@node_context.parent.name)
      end

      def is_link_object?
        return false if !@node_context || !@node_context.parent || !@node_context.parent.is_a?(Prism::CallNode)

        @node_context.parent.name == :link
      end
    end
  end
end