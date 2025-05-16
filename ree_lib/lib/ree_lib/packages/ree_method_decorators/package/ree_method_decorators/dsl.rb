# frozen_string_literal: true

package_require("ree_method_decorators/functions/decorate_method")

module ReeMethodDecorators::DSL
  TMP_DECORATORS_STORAGE_KEY = :@_ree_method_decorators_tmp
  DECORATORS_STORAGE_KEY = :@_ree_method_decorators

  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  module InstanceMethods
    attr_reader :context
    attr_accessor :method_name, :method_alias_name, :is_class_method, :target

    def call(...)
      @context = build_context(...)

      caller = get_caller

      decorators = caller.instance_variable_get(TMP_DECORATORS_STORAGE_KEY) || {}
      if decorators.key?(self.class.storage_key)
        raise Ree::Error.new(
          "Pending metadata for #{self.class} already exists on #{caller.inspect}",
          :invalid_dsl_usage
        )
      end

      decorators[self.class.storage_key] = self
      caller.instance_variable_set(TMP_DECORATORS_STORAGE_KEY, decorators)

      # TODO: move to on_link hook?
      if !caller.instance_variable_get(:@_ree_method_decoratable)
        caller.extend(CallerClassMethods)
        caller.instance_variable_set(:@_ree_method_decoratable, true)
      end

      nil
    end

    def build_context
      nil
    end

    def storage_key
      self.class.storage_key
    end

    def freeze
      context.freeze
      super if defined?(super)
    end
  end

  module ClassMethods
    def method_decorator(name, &proc)
      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, self, :fn
      )

      dsl.instance_exec(&proc) if block_given?
      dsl.tags(["method_decorator"])
      dsl.target(:class)
      dsl.with_caller
      dsl.freeze(false)
      dsl.object.set_as_compiled(false)

      Ree.container.compile(dsl.package, name)

      nil
    end

    def storage_key
      object_id
    end
  end

  module CallerClassMethods
    def method_added(name)
      ReeMethodDecorators::DecorateMethod.new.call(self, name, false)
      super if defined?(super)
    end

    def singleton_method_added(name)
      ReeMethodDecorators::DecorateMethod.new.call(self, name, true)
      super if defined?(super)
    end
  end
end
