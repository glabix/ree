# frozen_string_literal: true

module Ree::Contracts
  class MethodDecorator
    class << self
      def active?
        !Ree::Contracts.no_contracts?
      end

      def decorator_id(target, method_name, is_class_method)
        "#{target.object_id}#{target.name}#{method_name}#{is_class_method}"
      end

      def add_decorator(decorator)
        decorators[decorator.id] = decorator
      end

      def get_decorator(id)
        decorators[id]
      end

      def decorators
        @decorators ||= {}
      end
    end

    include Ree::Args
    
    attr_reader :target # [Class] class ot superclass of decorated method
    attr_reader :method_name # [Symbol] original method name
    attr_reader :method_parameters # [Array] list of original method parameters
    attr_reader :is_class_method # [Bool]
    attr_reader :contract_definition # [ContractDefinition] definition of contract
    attr_reader :errors # [Nilor[ArrayOf[Class]]] list of thrown errors
    attr_reader :doc # [Nilor[String]] rdoc
    attr_reader :args # [CalledArgsValidator]
    attr_reader :return_validator # [BaseValidator] validator for return value

    def initialize(method_name, is_class_method, target)
      check_arg(method_name, :method_name, Symbol)
      check_bool(is_class_method, :is_class_method)
      check_arg_any(target, :target, [Class, Module])

      engine = Engine.fetch_for(target)

      @method_name = method_name
      @is_class_method = is_class_method
      @target = target
      @contract_definition = engine.fetch_contract
      @errors = engine.fetch_errors
      @doc = engine.fetch_doc
    end

    def call(plugin_mode: true)
      return nil if Ree::Contracts.no_contracts?
      return nil unless contract_definition

      # Store decorator for runtime lookups (still needed)
      self.class.add_decorator(self)

      # Get method parameters from the method (before aliasing)
      # Note: We get params from the current method, not __ree_original_#{method_name}
      # because the alias hasn't been created yet when plugins are called
      @method_parameters = alias_target
        .instance_method(method_name)
        .parameters
        .freeze

      @args = CalledArgsValidator.new(
        contract_definition,
        method_parameters,
        printed_name
      )

      @return_validator = Validators.fetch_for(contract_definition.return_contract)

      if plugin_mode
        # Plugin mode: Return wrapper lambda for composition
        build_contract_wrapper
      else
        # Legacy mode: Apply wrapper directly (for Contractable standalone usage)
        apply_contract_wrapper_directly
      end
    end

    # Unique ID of this Method Decorator
    def id
      @id ||= self.class.decorator_id(target, method_name, is_class_method)
    end

    # Target class to be used for alias method definition
    def alias_target
      @alias_target ||= begin
        return Utils.eigenclass_of(target) if is_class_method
        target
      end
    end

    # Public method used by legacy contract wrapper (called from class_eval'd method)
    def validate_and_call(instance, method_alias, args, kwargs, &blk)
      @args.call(args, kwargs, blk)
      result = instance.send(method_alias, *args, **kwargs, &blk)

      unless @return_validator.call(result)
        raise ReturnContractError, "Invalid return value for #{printed_name}\n  #{
          @return_validator.message(result, 'returns', 0).strip
        }"
      end

      result
    end

    private

    def build_contract_wrapper
      args_validator = @args
      return_validator = @return_validator
      decorator_printed_name = printed_name

      Proc.new do |instance, next_layer, *args, **kwargs, &block|
        # Validate arguments
        args_validator.call(args, kwargs, block)

        # Call next layer
        result = next_layer.call(*args, **kwargs, &block)

        # Validate return value
        unless return_validator.call(result)
          raise ReturnContractError, "Invalid return value for #{decorator_printed_name}\n  #{
            return_validator.message(result, 'returns', 0).strip
          }"
        end

        result
      end
    end

    def apply_contract_wrapper_directly
      # Legacy mode for Contractable standalone usage
      # Detect visibility BEFORE creating alias
      visibility = if alias_target.private_instance_methods.include?(method_name)
        :private
      elsif alias_target.protected_instance_methods.include?(method_name)
        :protected
      else
        :public
      end

      # Create our own alias and wrapper
      method_alias = :"__original_#{method_name}_#{SecureRandom.hex}"
      alias_target.alias_method(method_alias, method_name)

      args_validator = @args
      return_validator = @return_validator
      decorator_printed_name = printed_name

      file, line = alias_target.instance_method(method_alias).source_location

      alias_target.class_eval(%Q(
        def #{method_name}(*args, **kwargs, &blk)
          decorator = Ree::Contracts::MethodDecorator.get_decorator('#{id}')
          decorator.validate_and_call(self, #{method_alias.inspect}, args, kwargs, &blk)
        end
      ), file, line - 3)

      # Restore visibility
      case visibility
      when :private
        alias_target.send(:private, method_name, method_alias)
      when :protected
        alias_target.send(:protected, method_name, method_alias)
      end
    end

    def private_method?
      return target.private_methods.include?(method_name) if is_class_method
      target.private_instance_methods.include?(method_name)
    end

    def protected_method?
      return target.protected_methods.include?(method_name) if is_class_method
      target.protected_instance_methods.include?(method_name)
    end

    def printed_name
      @printed_name ||= "#{target}#{is_class_method ? '.' : '#'}#{method_name}"
    end
  end
end
