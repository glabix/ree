module Ree::MethodDecorators
  module Decoratable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def method_added(name)
        decorators = Ree::MethodDecorators::DefinitionStorage.delete(self)
        if decorators&.any?
          Ree::MethodDecorators::DecoratorBuilder.new(name, false, self, decorators).call
        end
        super if defined?(super)
      end

      def singleton_method_added(name)
        decorators = Ree::MethodDecorators::DefinitionStorage.delete(self)
        if decorators&.any?
          Ree::MethodDecorators::DecoratorBuilder.new(name, true, self, decorators).call
        end
        super if defined?(super)
      end
    end

    def self.with(decorators)
      Module.new do
        define_singleton_method(:included) do |base|
          base.extend(ClassMethods)
          decorators.each do |name, decorator_class|
            decorator_class.register(base, name)
          end
        end
      end
    end
  end
end
