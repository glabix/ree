# frozen_string_literal: true

module ReeDecorators
  autoload :BaseValidator, 'ree_decorators/validators/base_validator'
  autoload :ArrayValidator, 'ree_decorators/validators/array_validator'
  autoload :ClassValidator, 'ree_decorators/validators/class_validator'
  autoload :DefaultValidator, 'ree_decorators/validators/default_validator'
  autoload :HashValidator, 'ree_decorators/validators/hash_validator'
  autoload :ProcValidator, 'ree_decorators/validators/proc_validator'
  autoload :RangeValidator, 'ree_decorators/validators/range_validator'
  autoload :RegexpValidator, 'ree_decorators/validators/regexp_validator'
  autoload :ValidValidator, 'ree_decorators/validators/valid_validator'

  class Validators
    FORBIDDEN_CONTRACTS = Set.new([
      ArgContracts::None, ArgContracts::Kwargs,
      ArgContracts::Block, ArgContracts::Optblock,
      ArgContracts::SplatOf, ArgContracts::Splat
    ]).freeze

    class << self
      def fetch_for(contract)
        validators[contract.object_id] ||= build(contract)
      end

      private

      def build(contract)
        if FORBIDDEN_CONTRACTS.include?(contract)
          raise Ree::Error.new("#{contract} is not supported arg validator", :invalid_dsl_usage)
        end

        return ProcValidator.new(contract) if contract.is_a?(Proc)
        return ArrayValidator.new(contract) if contract.is_a?(Array)
        return HashValidator.new(contract) if contract.is_a?(Hash)
        return RangeValidator.new(contract) if contract.is_a?(Range)
        return RegexpValidator.new(contract) if contract.is_a?(Regexp)
        return ValidValidator.new(contract) if contract.respond_to?(:valid?)
        return ClassValidator.new(contract) if contract.is_a?(Class) || contract.is_a?(Module)

        DefaultValidator.new(contract)
      end

      def validators
        @validators ||= {}
      end
    end
  end
end
