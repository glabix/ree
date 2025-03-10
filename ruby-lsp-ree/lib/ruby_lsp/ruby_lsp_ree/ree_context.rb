require 'prism'

module RubyLsp
  module Ree
    class ReeContext
      ERROR_DEFINITION_NAMES = [
        'auth_error',
        'build_error',
        'conflict_error',
        'invalid_param_error',
        'not_found_error',
        'payment_required_error',
        'permission_error',
        'validation_error'
      ]

      def initialize(node_context)
        @node_context = node_context
      end

      def is_error_definition?
        return false if !@node_context || !@node_context.parent || !@node_context.parent.is_a?(Prism::CallNode)
        
        ERROR_DEFINITION_NAMES.include?(@node_context.parent.name.to_s)
      end
    end
  end
end