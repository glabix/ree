# frozen_string_literal: true

package_require("ree_decorators/functions/decorate_method")

module ReeDecorators::DSL
  def self.included(base)
    validate(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.include(Ree::Inspectable)
  end

  def self.validate(base)
    if !base.is_a?(Class)
      raise ArgumentError, "ReeDecorators::DSL should be included to named classed only"
    end

    if base.name.nil? || base.name.empty?
      raise ArgumentError, "ReeDecorators::DSL does not support anonymous classes"
    end
  end

  module InstanceMethods
    attr_reader :context
    attr_accessor :method_name, :method_alias_name, :is_class_method, :target

    def call(...)
      return if ReeDecorators.decorator_disabled?(self.class)

      @context = build_context(...)

      decorator_store.set_pending_decorator(get_caller, self)

      nil
    end

    def build_context
      nil
    end

    def id
      self.class.id
    end

    def freeze
      context.freeze
      super if defined?(super)
    end
  end

  module ClassMethods
    def decorator(name, &proc)
      decorator = self

      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, decorator, :fn
      )

      dsl.instance_exec(&proc) if block_given?
      dsl.tags(["decorator"])
      dsl.target(:class)
      dsl.with_caller
      dsl.freeze(false)
      dsl.object.set_as_compiled(false)

      dsl.on_link do |base|
        if !ReeDecorators.decorator_disabled?(decorator)
          base.extend(CallerClassMethods)
        end
      end

      dsl.link :decorator_store, from: :ree_decorators

      Ree.container.compile(dsl.package, name)

      nil
    end

    def id
      object_id
    end
  end

  module CallerClassMethods
    def method_added(name)
      ReeDecorators::DecorateMethod.new.call(self, name, false)
      super if defined?(super)
    end

    def singleton_method_added(name)
      ReeDecorators::DecorateMethod.new.call(self, name, true)
      super if defined?(super)
    end
  end
end
