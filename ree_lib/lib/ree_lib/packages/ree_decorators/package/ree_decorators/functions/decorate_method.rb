# frozen_string_literal: true

class ReeDecorators::DecorateMethod
  include Ree::FnDSL

  fn :decorate_method do
    link :get_alias_target
    link :decorator_store

    target :class
  end

  # @api private
  def call(target, method_name, is_class_method)
    decorators = decorator_store.delete_pending_decorators(target)

    return if !decorators&.any?

    decorator_store.set_method_decorators(target, decorators, method_name, is_class_method)

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

  def create_decorated_method(target, alias_target, method_alias_name, method_name, decorators, is_class_method)
    file, line = alias_target.instance_method(method_alias_name).source_location
    hookable_decorators = if ReeDecorators.no_decorators?
      []
    else
      decorators.select { _1.respond_to?(:hook) && !ReeDecorators.decorator_disabled?(_1.class) }
    end

    method_visibility = if private_method?(alias_target, method_alias_name, is_class_method)
      "private "
    elsif protected_method?(alias_target, method_alias_name, is_class_method)
      "protected "
    else
      nil
    end

    decorator_chain = build_decorator_chain(hookable_decorators, method_name, method_alias_name)

    params = if hookable_decorators.empty?
      "..."
    else
      "*args, **kwargs, &blk"
    end

    get_decorators = if hookable_decorators.empty?
      ""
    else
      <<~RUBY
        decorators = ReeDecorators::DecoratorStore.new
          .get_method_decorators(#{target.name}, :#{method_name}, #{is_class_method})
      RUBY
    end

    alias_target.class_eval(<<~RUBY, file, line)
      #{method_visibility}def #{method_name}(#{params})
        #{get_decorators}
        #{decorator_chain}
      end
    RUBY
  end

  def build_decorator_chain(decorators, method_name, method_alias_name)
    base_call = if decorators.empty?
      "#{method_alias_name}(...)"
    else
      "#{method_alias_name}(*args, **kwargs, &blk)"
    end

    decorators.reverse.reduce(base_call) do |chain, decorator|
      <<~RUBY
        decorator = decorators&.fetch(#{decorator.id}, nil)
        if decorator.nil?
          raise Ree::Error.new("Decorator #{decorator.class} not found for `#{method_name}` method")
        end

        decorator.hook(self, args, kwargs, blk) do |args, kwargs, blk|
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
