# frozen_string_literal: true

class ReeDecorators::UpdateContractDefinition
  include Ree::FnDSL

  fn :update_contract_definition do
    link "ree_decorators/arg_contracts", -> { ArgContracts }
  end

  def call(contract_definition, params, printed_name)
    contracts = contract_definition.arg_contracts
    block_contract = contract_definition.block_contract

    validate_kwargs(contracts, params, printed_name)

    arg_contracts = []

    contracts.each do |contract|
      next if contract.is_a?(ArgContracts::None)

      if contract.is_a?(ArgContracts::Kwargs)
        contract.each do |key, cont|
          arg_contracts << ArgContract.new(:key, contract, key)
        end
      elsif contract.is_a?(ArgContracts::SplatOf)
        arg_contracts << ArgContract.new(:splat, contract, nil)
      elsif contract.is_a?(ArgContracts::Splat)
        arg_contracts << ArgContract.new(:splat, contract, nil)
      elsif contract.is_a?(ArgContracts::Ksplat)
        arg_contracts << ArgContract.new(:ksplat, contract, nil)
      else
        arg_contracts << ArgContract.new(:ord, contract, nil)
      end
    end

    if block_contract
      arg_contracts << ArgContract.new(:block, block_contract, nil)
    end

    if arg_contracts.size != params.size
      msgs = [default_msg(printed_name)]
      msgs << "\t - contract count is not equal to argument count"
      msgs << "\t - contract count: #{arg_contracts.size}"
      msgs << "\t - argument count: #{params.size}"
      raise BadContractError, msgs.join("\n")
    end

    arg_contracts.each_with_index do |arg_contract, index|
      type, name = params[index]

      validator, contract = if (type == :req || type == :opt)
        if arg_contract.type == :ord
          [Validators.fetch_for(arg_contract.contract), arg_contract.contract]
        end
      elsif type == :key || type == :keyreq
        if arg_contract.type == :key
          [Validators.fetch_for(arg_contract.contract[name]), arg_contract.contract[name]]
        elsif arg_contract.type == :ord
          [Validators.fetch_for(arg_contract.contract), arg_contract.contract]
        end
      elsif type == :rest
        if arg_contract.type == :splat
          [Validators.fetch_for(arg_contract.contract), arg_contract.contract]
        end
      elsif type == :keyrest
        if arg_contract.type == :ksplat
          [Validators.fetch_for(arg_contract.contract), arg_contract.contract]
        end
      elsif type == :block
        if arg_contract.type == :block
          [nil, arg_contract.contract]
        end
      else
        raise NotImplementedError, "type `#{type}` is not supported. Message gem owner to add it :)"
      end

      if validator.nil? && contract.nil?
        msgs = [default_msg]
        msgs << "\t - invalid contract for `#{name}` argument => #{arg_contract.contract.inspect}"
        raise BadContractError, msgs.join("\n")
      end

      @args[name] = Arg.new(name, type, validator, contract)
    end
  end

  private

  def default_msg(printed_name)
    "Contract definition mismatches method definition for #{printed_name}"
  end

  def validate_kwargs(contracts, params, printed_name)
    all_keyword_args = params.select { |type, _| type == :keyreq || type == :key }
    opt_keyword_args = params.select { |type, _| type == :key }

    kwarg_contract = contracts.detect { _1.is_a?(ArgContracts::Kwargs) }

    if opt_keyword_args.any?
      if kwarg_contract.nil?
        msgs = [default_msg(printed_name)]
        msgs << "\t - methods with optional keyword arguments should use Kwargs[...] to describe all keyword args"
        raise BadContractError, msgs.join("\n")
      else
        missing_keys = all_keyword_args.map { _2 } - kwarg_contract.keys

        if missing_keys.any?
          msgs = [default_msg(printed_name)]

          missing_keys.each do |key|
            msgs << "\t - missing Kwargs contract for keyword argument `#{key}`"
          end
          raise BadContractError, msgs.join("\n")
        end
      end
    elsif kwarg_contract && all_keyword_args.empty?
      msgs = [default_msg(printed_name)]
      msgs << "\t - Kwargs contract should be used to describe keyword arguments only"
      raise BadContractError, msgs.join("\n")
    end
  end
end
