module Ree::MethodDecorators
  module Decoratable
    module Helper
      def self.apply_decorators(target, name, is_class_method)
        decorators = Ree::MethodDecorators::DefinitionStorage.delete(target)
        if decorators&.any?
          Ree::MethodDecorators::DecoratorBuilder.new(name, is_class_method, target, decorators).call
        end
      end
    end

    module ClassMethods
      def method_added(name)
        Helper.apply_decorators(self, name, false)
        super if defined?(super)
      end

      def singleton_method_added(name)
        Helper.apply_decorators(self, name, true)
        super if defined?(super)
      end
    end

    def self.included(base)
      return if Ree::MethodDecorators.no_method_decorators?

      base.extend(ClassMethods)
    end

    def self.register(target, name, decorator_class)
      target.define_singleton_method(name) do |*args, **kwargs, &block|
        next if Ree::MethodDecorators.decorator_disabled?(decorator_class)

        decorator = decorator_class.new(*args, **kwargs, &block)
        Ree::MethodDecorators::DefinitionStorage.set(self, name, decorator)
        decorator
      end
    end

    # DSL for including with decorator registration
    def self.with(decorators)
      @module_cache ||= {}
      @module_cache[decorators] ||= Module.new do
        define_singleton_method(:included) do |base|
          base.extend(ClassMethods)
          decorators.each do |name, decorator_class|
            Decoratable.register(base, name, decorator_class)
          end
        end
      end
    end
  end
end
