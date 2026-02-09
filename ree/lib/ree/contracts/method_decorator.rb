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

    def call
      return if Ree::Contracts.no_contracts?
      return unless contract_definition

      self.class.add_decorator(self)

      original_alias = :"__ree_original_#{method_name}"
      param_source = if alias_target.method_defined?(original_alias)
        original_alias
      else
        method_name
      end

      @method_parameters = alias_target
        .instance_method(param_source)
        .parameters
        .freeze

      @args = CalledArgsValidator.new(
        contract_definition,
        method_parameters,
        printed_name
      )

      @return_validator = Validators.fetch_for(contract_definition.return_contract)

      make_alias
      make_definition
    end

    def execute_on(target, args, kwargs, &blk)
      @args.call(args, kwargs, blk)
      result = target.send(method_alias, *args, **kwargs, &blk)

      if !return_validator.call(result)
        raise ReturnContractError, "Invalid return value for #{printed_name}\n  #{
          return_validator.message(result, 'returns', 0).strip
        }"
      end

      result
    end

    # Unique ID of this Method Decorator
    def id
      @id ||= self.class.decorator_id(target, method_name, is_class_method)
    end

    # Alias name for original method
    def method_alias
      @method_alias ||= :"__original_#{method_name}_#{SecureRandom.hex}"
    end

    # Target class to be used for alias method definition
    def alias_target
      @alias_target ||= begin
        return Utils.eigenclass_of(target) if is_class_method
        target
      end
    end

    private

    def make_alias
      alias_target.alias_method(method_alias, method_name)
    end

    def make_definition
      file, line = alias_target.instance_method(method_alias).source_location

      alias_target.class_eval(%Q(
        def #{method_name}(*args, **kwargs, &blk)
          decorator = Ree::Contracts::MethodDecorator.get_decorator('#{id}')
          decorator.execute_on(self, args, kwargs, &blk)
        end
      ), file, line - 3)

      make_private if private_method?
      make_protected if protected_method?
    end

    def private_method?
      return target.private_methods.include?(method_alias) if is_class_method
      target.private_instance_methods.include?(method_alias)
    end

    def protected_method?
      return target.protected_methods.include?(method_alias) if is_class_method
      target.protected_instance_methods.include?(method_alias)
    end

    def make_private
      _method_name = method_name
      _method_alias = method_alias

      alias_target.class_eval do
        private _method_name
        private _method_alias
      end
    end

    def make_protected
      _method_name = method_name
      _method_alias = method_alias

      alias_target.class_eval do
        protected _method_name
        protected _method_alias
      end
    end

    def printed_name
      @printed_name ||= "#{target}#{is_class_method ? '.' : '#'}#{method_name}"
    end
  end
end
