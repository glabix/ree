# frozen_string_literal: true

module Ree::MethodAddedHook
  def method_added(name)
    plugins = Ree.method_added_plugins.select(&:active?)
    return super if plugins.empty?
    return if @__ree_plugin_running

    @__ree_plugin_running = true

    original_alias = :"__ree_original_#{name}"
    remove_method(original_alias) if method_defined?(original_alias)
    alias_method(original_alias, name)

    begin
      plugins.each do |plugin_class|
        plugin_class.new(name, false, self).call
      end
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

    original_alias = :"__ree_original_#{name}"
    eigenclass = class << self; self; end

    if eigenclass.method_defined?(original_alias)
      eigenclass.remove_method(original_alias)
    end
    eigenclass.alias_method(original_alias, name)

    begin
      plugins.each do |plugin_class|
        plugin_class.new(name, true, self).call
      end
    ensure
      @__ree_singleton_plugin_running = false
    end

    super
  end
end
