module RubyLsp
  module Ree
    module ReeConstants
      LINK_DSL_MODULE = 'Ree::LinkDSL'
  
      LINKS_CONTAINER_TYPES = [
        :fn,
        :action,
        :dao,
        :bean,
        :async_bean,
        :mapper,
        :aggregate
      ]

      ERROR_DEFINITION_NAMES = [
        :auth_error,
        :build_error,
        :conflict_error,
        :invalid_param_error,
        :not_found_error,
        :payment_required_error,
        :permission_error,
        :validation_error
      ]

      CONTRACT_CALL_NODE_NAMES = [
        :contract,
        :throws
      ]
    end
  end
end