require 'prism'
require_relative "ree_constants"

module RubyLsp
  module Ree
    class ReeContext
      include RubyLsp::Ree::ReeConstants

      FROM_ARG_KEY = 'from'

      def initialize(node_context)
        @node_context = node_context
      end

      def is_error_definition?
        return false unless has_call_parent?
        
        ERROR_DEFINITION_NAMES.include?(@node_context.parent.name)
      end

      def is_link_object?
        return false unless has_call_parent?

        @node_context.parent.name == :link ||  @node_context.parent.name == :import
      end

      def is_package_argument?
        return false unless has_call_parent?
        return false if !@node_context.parent.arguments || @node_context.parent.arguments.arguments.size < 2
        return false if @node_context.node.unescaped == @node_context.parent.arguments.arguments.first.unescaped

        kw_args = @node_context.parent.arguments.arguments.detect{ |arg| arg.is_a?(Prism::KeywordHashNode) }
        return false unless kw_args
    
        package_param = kw_args.elements.detect{ _1.key.unescaped == FROM_ARG_KEY }
        package_param.value.unescaped == @node_context.node.unescaped
      end

      private

      def has_call_parent?
        @node_context && @node_context.parent && @node_context.parent.is_a?(Prism::CallNode)
      end
    end
  end
end