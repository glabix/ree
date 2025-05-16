# frozen_string_literal: true

require 'securerandom'

class ReeMethodDecorators::DecorateMethod
  include Ree::FnDSL

  fn :decorate_method do
    link :get_alias_target

    target :class
  end

  # @api private
  def call(target, method_name, is_class_method)
    return if !target.instance_variable_defined?(ReeMethodDecorators::DSL::TMP_DECORATORS_STORAGE_KEY)
    decorators = target.remove_instance_variable(ReeMethodDecorators::DSL::TMP_DECORATORS_STORAGE_KEY)

    return if !decorators&.any?

    decorators_storage = target.instance_variable_get(ReeMethodDecorators::DSL::DECORATORS_STORAGE_KEY)
    if decorators_storage.nil?
      decorators_storage = {}
      target.instance_variable_set(ReeMethodDecorators::DSL::DECORATORS_STORAGE_KEY, decorators_storage)
    end
    decorators_storage[build_decorators_storage_key(method_name, is_class_method)] = decorators

    # TODO: handle alias method name collision
    method_alias_name = build_method_alias_name(method_name)

    decorators.each do |_key, decorator|
      decorator.method_name = method_name
      decorator.method_alias_name = method_alias_name
      decorator.is_class_method = is_class_method
      decorator.target = target

      decorator.before_decorate if decorator.respond_to?(:before_decorate)
    end

    alias_target = get_alias_target(target, is_class_method)


    # TODO: skip decorating if there is no hookable decorators
    alias_original_method(alias_target, method_alias_name, method_name)
    create_decorated_method(target, alias_target, method_alias_name, method_name, decorators.values, is_class_method)

    # Original method should be private
    make_private(alias_target, method_alias_name)

    decorators.each(&:freeze)
    decorators.freeze

    nil
  end

  private

  def alias_original_method(alias_target, method_alias_name, method_name)
    alias_target.alias_method(method_alias_name, method_name)
  end

  def build_method_alias_name(method_name)
    :"__original_#{method_name}_#{SecureRandom.hex}"
  end

  def build_decorators_storage_key(method_name, is_class_method)
    "#{method_name}_#{is_class_method ? "class" : "instance"}"
  end

  def create_decorated_method(target, alias_target, method_alias_name, method_name, decorators, is_class_method)
    file, line = alias_target.instance_method(method_alias_name).source_location
    hookable_decorators = decorators.select { _1.respond_to?(:hook) }

    method_visibility = if private_method?(alias_target, method_alias_name, is_class_method)
      "private "
    elsif protected_method?(alias_target, method_alias_name, is_class_method)
      "protected "
    else
      nil
    end

    alias_target.class_eval(<<~RUBY, file, line)
      #{method_visibility}def #{method_name}(*args, **kwargs, &blk)
        decorators = #{target.name}
          .instance_variable_get(ReeMethodDecorators::DSL::DECORATORS_STORAGE_KEY)
          .fetch("#{build_decorators_storage_key(method_name, is_class_method)}")
        #{build_decorator_chain(hookable_decorators, method_name, method_alias_name)}
      end
    RUBY
  end

  def build_decorator_chain(decorators, method_name, method_alias_name)
    base_call = "#{method_alias_name}(*args, **kwargs, &blk)"

    decorators.reverse.reduce(base_call) do |chain, decorator|
      <<~RUBY
        decorator = decorators.fetch(#{decorator.storage_key})
        decorator.hook(self, args, kwargs, blk) do |*args, **kwargs, &blk|
          #{chain}
        end
      RUBY
    end
  end

  def private_method?(target, method_name, is_class_method)
    return target.private_methods.include?(method_name) if is_class_method
    target.private_instance_methods.include?(method_name)
  end

  def protected_method?(target, method_name, is_class_method)
    return target.protected_methods.include?(method_name) if is_class_method
    target.protected_instance_methods.include?(method_name)
  end

  def make_private(alias_target, method_name)
    alias_target.class_eval do
      private method_name
    end
  end

  def make_protected(alias_target, method_name)
    alias_target.class_eval do
      protected method_name
    end
  end
end
