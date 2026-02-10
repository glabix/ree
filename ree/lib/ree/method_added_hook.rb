# frozen_string_literal: true

module Ree::MethodAddedHook
  def method_added(name)
    plugins = Ree.method_added_plugins.select(&:active?)
    return super if plugins.empty?
    return if @__ree_plugin_running

    @__ree_plugin_running = true

    begin
      # Collect wrapper lambdas from plugins (some may return nil)
      wrappers = plugins.map { |plugin_class| plugin_class.new(name, false, self).call }.compact

      if wrappers.empty?
        @__ree_plugin_running = false
        return super
      end

      # Create single alias for original implementation
      original_alias = :"__ree_original_#{name}"
      remove_method(original_alias) if method_defined?(original_alias)
      alias_method(original_alias, name)

      # Compose all wrappers into a single method
      compose_method(name, original_alias, wrappers)
    ensure
      @__ree_plugin_running = false
    end

    super
  end

  def singleton_method_added(name)
    plugins = Ree.method_added_plugins.select(&:active?)
    return super if plugins.empty?
    return if @__ree_singleton_plugin_running

    @__ree_singleton_plugin_running = true

    eigenclass = class << self; self; end

    begin
      # Collect wrapper lambdas from plugins (some may return nil)
      wrappers = plugins.map { |plugin_class| plugin_class.new(name, true, self).call }.compact

      if wrappers.empty?
        @__ree_singleton_plugin_running = false
        return super
      end

      # Create single alias for original implementation
      original_alias = :"__ree_original_#{name}"
      eigenclass.remove_method(original_alias) if eigenclass.method_defined?(original_alias)
      eigenclass.alias_method(original_alias, name)

      # Compose all wrappers into a single method
      compose_singleton_method(eigenclass, name, original_alias, wrappers)
    ensure
      @__ree_singleton_plugin_running = false
    end

    super
  end

  private

  def compose_method(method_name, original_alias, wrappers)
    # Detect original method visibility
    visibility = if private_method_defined?(original_alias)
      :private
    elsif protected_method_defined?(original_alias)
      :protected
    else
      :public
    end

    # Build executor chain from inside out
    define_method(method_name) do |*args, **kwargs, &block|
      # Innermost layer: call the original method
      # Note: next_layer signature is: ->(){ ... } to be called with .call(*args, **kwargs, &block)
      executor = ->(*a, **kw, &b) { send(original_alias, *a, **kw, &b) }

      # Wrap from inside out (reverse to make first plugin outermost)
      wrappers.reverse_each do |wrapper|
        current_executor = executor
        # Wrapper receives: (instance, next_layer, *args, **kwargs, &block)
        # We need to create a next_layer that calls current_executor
        next_layer = ->(*a, **kw, &b) { current_executor.call(*a, **kw, &b) }
        executor = ->(*a, **kw, &b) { wrapper.call(self, next_layer, *a, **kw, &b) }
      end

      # Execute the composed chain
      executor.call(*args, **kwargs, &block)
    end

    # Restore original visibility
    case visibility
    when :private
      private method_name
    when :protected
      protected method_name
    end
  end

  def compose_singleton_method(eigenclass, method_name, original_alias, wrappers)
    # Detect original method visibility
    visibility = if eigenclass.private_method_defined?(original_alias)
      :private
    elsif eigenclass.protected_method_defined?(original_alias)
      :protected
    else
      :public
    end

    # Build executor chain from inside out
    eigenclass.define_method(method_name) do |*args, **kwargs, &block|
      # Innermost layer: call the original method
      # Note: next_layer signature is: ->(){ ... } to be called with .call(*args, **kwargs, &block)
      executor = ->(*a, **kw, &b) { send(original_alias, *a, **kw, &b) }

      # Wrap from inside out (reverse to make first plugin outermost)
      wrappers.reverse_each do |wrapper|
        current_executor = executor
        # Wrapper receives: (instance, next_layer, *args, **kwargs, &block)
        # We need to create a next_layer that calls current_executor
        next_layer = ->(*a, **kw, &b) { current_executor.call(*a, **kw, &b) }
        executor = ->(*a, **kw, &b) { wrapper.call(self, next_layer, *a, **kw, &b) }
      end

      # Execute the composed chain
      executor.call(*args, **kwargs, &block)
    end

    # Restore original visibility
    case visibility
    when :private
      eigenclass.send(:private, method_name)
    when :protected
      eigenclass.send(:protected, method_name)
    end
  end
end
