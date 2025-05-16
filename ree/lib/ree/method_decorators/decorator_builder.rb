# frozen_string_literal: true

module Ree::MethodDecorators
  class DecoratorBuilder
    include Ree::Args

    attr_reader :method_name, :is_class_method, :target, :decorators

    def initialize(method_name, is_class_method, target, decorators)
      check_arg_any(target, :target, [Class, Module])

      @method_name = method_name
      @is_class_method = is_class_method
      @target = target
      @decorators = decorators
    end

    def call
      return if decorators.empty?

      decorators.each do |decorator|
        DecoratorStorage.set(target, method_name, decorator)

        decorator.method_name = method_name
        decorator.is_class_method = is_class_method
        decorator.target = target

        decorator.before_decorate if decorator.respond_to?(:before_decorate)
      end

      alias_original_method
      create_decorated_method
      make_private(method_alias_name)

      decorators.each(&:freeze)
    end

    private

    def alias_original_method
      alias_target.alias_method(method_alias_name, method_name)
    end

    def method_alias_name
      @method_alias_name ||= :"__original_#{method_name}_#{SecureRandom.hex}"
    end

    def alias_target
      @alias_target ||= begin
        return Ree::ClassUtils.eigenclass_of(target) if is_class_method
        target
      end
    end

    def private_method?
      return target.private_methods.include?(method_alias_name) if is_class_method
      target.private_instance_methods.include?(method_alias_name)
    end

    def protected_method?
      return target.protected_methods.include?(method_alias_name) if is_class_method
      target.protected_instance_methods.include?(method_alias_name)
    end

    def make_private(method_name)
      alias_target.class_eval do
        private method_name
      end
    end

    def make_protected(method_name)
      alias_target.class_eval do
        protected method_name
      end
    end

    def create_decorated_method
      file, line = alias_target.instance_method(method_alias_name).source_location
      hookable_decorators = decorators.select { |decorator| decorator.respond_to?(:hook) }

      alias_target.class_eval(<<~RUBY, file, line)
        def #{method_name}(*args, **kwargs, &blk)
          #{build_decorator_chain(hookable_decorators)}
        end
      RUBY

      make_private(method_name) if private_method?
      make_protected(method_name) if protected_method?
    end

    def build_decorator_chain(decorators)
      base_call = "#{method_alias_name}(*args, **kwargs, &blk)"

      decorators.reverse.reduce(base_call) do |chain, decorator|
        key = DecoratorStorage.key(target, method_name, decorator.class)
        <<~RUBY
          decorator = Ree::MethodDecorators::DecoratorStorage.fetch("#{key}")
          decorator.hook(self, args, kwargs, blk) do |*args, **kwargs, &blk|
            #{chain}
          end
        RUBY
      end
    end
  end
end
