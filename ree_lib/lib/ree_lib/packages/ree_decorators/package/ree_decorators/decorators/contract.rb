# frozen_string_literal: true

class ReeDecorators::Contract
  include ReeDecorators::DSL

  decorator :contract do
    link :build_contract_definition
    link :validate_called_args
  end

  def build_context(*contract)
    OpenStruct.new(
      contract_definition: build_contract_definition(contract),
      printed_name: nil
    )
  end

  def before_decorate
    method_parameters = if is_class_method
      target.method(method_name).parameters.freeze
    else
      target.instance_method(method_name).parameters.freeze
    end

    context.contract_definition = update_contract_definition(
      context.contract_definition,
      method_parameters,
      printed_name
    )

    context.printed_name = "#{target}#{is_class_method ? '.' : '#'}#{method_name}"
  end

  def hook(receiver, args, kwargs, blk, &method_call)
    validate_called_args(
      block_contract: context.contract_definition.block_contract,
      method_parameters: context.method_parameters,
      printed_name: context.printed_name,
      args: args,
      kwargs: kwargs,
      blk: blk
    )

    result = method_call.call(args, kwargs, blk)

    validate_return_contract(contract_definition: context.contract_definition, result:)

    result
  end
end
