# frozen_string_literal: true

class ReeActions::MethodPlugin
  def self.active?
    true  # Always active when registered
  end

  def initialize(method_name, is_class_method, target)
    @method_name = method_name
    @is_class_method = is_class_method
    @target = target
  end

  def call
    # Only wrap :call method for classes that include ReeActions::DSL
    return nil unless @method_name == :call
    return nil unless ree_actions_class?

    Proc.new do |instance, next_layer, *args, **kwargs, &block|
      # ReeActions call signature: call(user_access, attrs, **opts, &block)
      # First arg is user_access, second is attrs (the one to cast)
      user_access, attrs, *rest_args = args

      if instance.class.const_defined?(:ActionCaster)
        caster = instance.class.const_get(:ActionCaster)

        unless caster.respond_to?(:cast)
          raise ArgumentError.new("ActionCaster does not respond to `cast` method")
        end

        attrs = begin
          caster.cast(attrs)
        rescue ReeMapper::TypeError, ReeMapper::CoercionError => e
          raise ReeActions::ParamError, e.message
        end
      end

      # Call next layer with cast attrs
      next_layer.call(user_access, attrs, *rest_args, **kwargs, &block)
    end
  end

  private

  def ree_actions_class?
    @target.included_modules.any? { |m| m.name == "ReeActions::DSL" }
  end
end
