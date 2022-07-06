# frozen_string_literal  = true

require 'securerandom'
require 'forwardable'
require 'delegate'

module Ree::Contracts
  autoload :ArgContracts, 'ree/contracts/arg_contracts'
  autoload :ArrayValidator, 'ree/contracts/validators/array_validator'
  autoload :BadContractError, 'ree/contracts/errors/bad_contract_error'
  autoload :BaseValidator, 'ree/contracts/validators/base_validator'
  autoload :CalledArgsValidator, 'ree/contracts/called_args_validator'
  autoload :ClassValidator, 'ree/contracts/validators/class_validator'
  autoload :Contractable, 'ree/contracts/contractable'
  autoload :ContractDefinition, 'ree/contracts/contract_definition'
  autoload :ContractError, 'ree/contracts/errors/contract_error'
  autoload :Core, 'ree/contracts/core'
  autoload :DefaultValidator, 'ree/contracts/validators/default_validator'
  autoload :Engine, 'ree/contracts/engine'
  autoload :EngineProxy, 'ree/contracts/engine_proxy'
  autoload :Error, 'ree/contracts/errors/error'
  autoload :HashValidator, 'ree/contracts/validators/hash_validator'
  autoload :MethodDecorator, 'ree/contracts/method_decorator'
  autoload :ProcValidator, 'ree/contracts/validators/proc_validator'
  autoload :RangeValidator, 'ree/contracts/validators/range_validator'
  autoload :RegexpValidator, 'ree/contracts/validators/regexp_validator'
  autoload :ReturnContractError, 'ree/contracts/errors/return_contract_error'
  autoload :Truncatable, 'ree/contracts/truncatable'
  autoload :Utils, 'ree/contracts/utils'
  autoload :Validators, 'ree/contracts/validators'
  autoload :ValidValidator, 'ree/contracts/validators/valid_validator'

  def self.no_contracts?
    ENV["NO_CONTRACTS"]
  end

  def self.get_method_decorator(target, method_name, scope: :instance)
    unless scope == :instance || scope == :class
      raise Ree::Error.new(':scope should be either :class or :instance', :invalid_dsl_usage)
    end

    decorator_id = MethodDecorator.decorator_id(target, method_name, scope == :class)
    MethodDecorator.get_decorator(decorator_id)
  end
end
