# frozen_string_literal: true

require 'set'

module Ree::Contracts
  class Validators
    FORBIDDEN_CONTRACTS = Set.new([
      ArgContracts::None, ArgContracts::Kwargs,
      ArgContracts::Block, ArgContracts::Optblock,
      ArgContracts::SplatOf, ArgContracts::Splat
    ])

    class << self
      def fetch_for(contract)
        validators[contract.object_id] ||= build(contract)
      end

      private

      def build(contract)
        if FORBIDDEN_CONTRACTS.include?(contract)
          name = contract.name.split("::").last
          raise Ree::Error.new("#{name} is not supported arg validator", :invalid_dsl_usage)
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
