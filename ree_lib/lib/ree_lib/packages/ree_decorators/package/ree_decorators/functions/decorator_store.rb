# frozen_string_literal: true

class ReeDecorators::DecoratorStore
  include Ree::BeanDSL

  bean :decorator_store do
    singleton
  end

  INSTANCE_VAR_KEY = :@_ree_decorators
  PENDING_KEY = nil

  # Get method decorator by method name and decorator id
  # @param target [Class, Module]
  # @param method_name [Symbol]
  # @param is_class_method [Boolean]
  # @param decorator_class [ReeDecorators::Decoratable]
  # @return [ReeDecorators::Decorator, nil]
  # @example
  #   decorator_store.get_method_decorator(Users::CreateUserCmd, :call, false, ReeDecorators::Contract)
  def get_method_decorator(target, method_name, is_class_method, decorator_class)
    get_decorator_store(target)&.dig(is_class_method, method_name, decorator_class.id)
  end

  # @api private
  def set_pending_decorator(target, decorator)
    pending_decorators = get_or_create_decorator_store(target, PENDING_KEY)

    if pending_decorators.key?(decorator.id)
      raise Ree::Error.new(
        "Pending metadata for #{decorator.class} already exists on #{target.inspect}",
        :invalid_dsl_usage
      )
    end

    pending_decorators[decorator.id] = decorator
    nil
  end

  # @api private
  # @return [Hash<Integer, ReeDecorators::Decorator>, nil]
  def delete_pending_decorators(target)
    get_decorator_store(target)&.delete(PENDING_KEY)
  end

  # @api private
  def set_method_decorators(target, method_decorators, method_name, is_class_method)
    decorator_store = get_or_create_decorator_store(target, is_class_method)
    decorator_store[method_name] = method_decorators
    nil
  end

  # @api private
  # @return [Hash<Integer, ReeDecorators::Decorator>, nil]
  def get_method_decorators(target, method_name, is_class_method)
    get_decorator_store(target)&.dig(is_class_method, method_name)
  end

  # @api private
  def get_or_create_decorator_store(target, location)
    decorator_store = get_decorator_store(target)

    if decorator_store.nil?
      decorator_store = { location => {} }
      target.instance_variable_set(INSTANCE_VAR_KEY, decorator_store)
    end

    location_store = decorator_store[location]

    if location_store.nil?
      location_store = {}
      decorator_store[location] = location_store
    end

    location_store
  end

  # @api private
  def get_decorator_store(target)
    target.instance_variable_get(INSTANCE_VAR_KEY)
  end
end
