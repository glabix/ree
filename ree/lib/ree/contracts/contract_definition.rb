# frozen_string_literal: true

module Ree::Contracts
  class ContractDefinition
    attr_reader :arg_contracts, :return_contract, :block_contract
    
    def initialize(contract)
      @arg_contracts, @return_contract = split_contract(contract)
      @block_contract = arg_contracts.pop if ArgContracts.opt_or_block?(arg_contracts.last)

      validate_block_contract
      validate_return_contract
      validate_kwargs_contract
      validate_splat_contract
      validate_ksplat_contract
      validate_dependent_contracts
    end

    private

    def validate_dependent_contracts
      splat_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::Splat) }
      splat_of_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::SplatOf) }
      kwargs_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::Kwargs) }
      ksplat_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::Ksplat) }

      if splat_index && kwargs_index && splat_index > kwargs_index
        raise BadContractError, "Splat contract should go before Kwargs"
      end

      if splat_of_index && kwargs_index && splat_of_index > kwargs_index
        raise BadContractError, "SplatOf contract should go before Kwargs"
      end

      if splat_index && ksplat_index && splat_index > ksplat_index
        raise BadContractError, "Splat contract should go before Ksplat"
      end

      if ksplat_index && kwargs_index && ksplat_index < kwargs_index
        raise BadContractError, "Ksplat contract should go after Kwargs"
      end
    end

    def validate_splat_contract
      splat_cont_number = arg_contracts.count { |cont| cont.is_a?(ArgContracts::Splat) }

      if splat_cont_number > 1
        raise BadContractError, "Multiple Splat contracts are not allowed"
      end

      splat_of_cont_number = arg_contracts.count { |cont| cont.is_a?(ArgContracts::SplatOf) }

      if splat_of_cont_number > 1
        raise BadContractError, "Multiple SplatOf contracts are not allowed"
      end
    end

    def validate_ksplat_contract
      ksplat_cont_number = arg_contracts.count { |cont| cont.is_a?(ArgContracts::Ksplat) }

      if ksplat_cont_number > 1
        raise BadContractError, "Multiple Ksplat contracts are not allowed"
      end

      kwargs = arg_contracts.detect { |cont| cont.is_a?(ArgContracts::Kwargs) }
      ksplat = arg_contracts.detect { |cont| cont.is_a?(ArgContracts::Ksplat) }

      if kwargs && ksplat
        keys = kwargs.contracts.keys & ksplat.validators.keys
      
        if keys.size > 0
          raise BadContractError, "Ksplat & Kwargs contracts has same keys #{keys.inspect}"
        end
      end
    end

    def validate_kwargs_contract
      kwargs_cont_number = arg_contracts.count { |cont| cont.is_a?(ArgContracts::Kwargs) }

      if kwargs_cont_number > 1
        raise BadContractError, "Only one Kwargs contract could be provided"
      end

      kwargs_cont_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::Kwargs) }
      ksplat_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::Ksplat) }
      splat_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::Splat) }
      splat_of_index = arg_contracts.index { |cont| cont.is_a?(ArgContracts::SplatOf) }

      if kwargs_cont_index && !ksplat_index && !splat_index && !splat_of_index
        return if kwargs_cont_index == arg_contracts.size - 1
        raise BadContractError, 'Kwargs contract should appear in the end'
      end
    end

    FORBIDDEN_RETURN_CONTRACTS = [
      ArgContracts::None, ArgContracts::Kwargs,
      ArgContracts::Block, ArgContracts::Optblock,
      ArgContracts::Splat, ArgContracts::Ksplat
    ]

    def validate_return_contract
      return if !FORBIDDEN_RETURN_CONTRACTS.include?(return_contract) && !FORBIDDEN_RETURN_CONTRACTS.include?(return_contract.class)
      raise BadContractError, "Contract for return value does not support None, Kwargs, Block, Optblock, Splat, Ksplat"
    end

    def validate_block_contract
      block_cont_idx = arg_contracts.index { |cont| ArgContracts.opt_or_block?(cont) }
      return if !block_cont_idx
      raise BadContractError, 'Block (Optblock) contract should appear in the end'
    end

    def split_contract(contract)
      last_contract = contract.last
      
      if last_contract.is_a?(Hash) && last_contract.one?
        last_arg_contract, return_contract = last_contract.first

        arg_contracts = contract[0..-2] + [last_arg_contract]

        if arg_contracts.any? { |cont| cont == ArgContracts::None }
          if arg_contracts.size > 1
            raise BadContractError, 'Combination of None contract with other contracts is not allowed'
          end

          arg_contracts = []
        end

        return [arg_contracts, return_contract]
      end

      return [[], contract.first] if contract.one?

      raise BadContractError, <<~STR
        It looks like your contract doesn't have a return value.
        A contract should be written as
          `contract arg1, arg2 => return_value`
        or
          `contract return_value`.
      STR
    end
  end
end
