# frozen_string_literal: true

require_relative 'method_decorator'
require_relative 'engine'
require_relative 'engine_proxy'

module Ree::Contracts
  module Contractable
    def method_added(name)
      return super if _ree_method_added_hook_active?
      MethodDecorator.new(name, false, self).call(plugin_mode: false)
      super
    end

    def singleton_method_added(name)
      return super if _ree_method_added_hook_active?
      MethodDecorator.new(name, true, self).call(plugin_mode: false)
      super
    end

    def doc(str)
      return if Ree::Contracts.no_contracts?
      
      engine = Engine.fetch_for(self)
      engine.add_doc(str.strip)
    end

    def contract(*args, &block)
      engine = Engine.fetch_for(self)
      engine.add_contract(*args, &block)
      EngineProxy.new(engine)
    end

    private

    def _ree_method_added_hook_active?
      is_a?(Ree::MethodAddedHook)
    end
  end
end
