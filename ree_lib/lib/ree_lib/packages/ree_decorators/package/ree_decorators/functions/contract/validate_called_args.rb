# frozen_string_literal: true

class ReeDecorators::ValidateCalledArgs
  include Ree::FnDSL

  fn :validate_called_args do
    link "ree_decorators/arg_contracts", -> { ArgContracts }
    link "ree_decorators/errors/contract_error", -> { ContractError }
  end

  def call(block_contract:, printed_name:, method_parameters:, args:, kwargs:, blk:)
    if block_contract == ArgContracts::Block && !blk
      msg = "missing required block"
      raise ContractError, "Wrong number of arguments for #{printed_name}\n\t - #{msg}"
    end

    errors = []

    validate_args(args, errors)
    validate_kwargs(kwargs, errors)

    return if errors.empty?

    msg = error_message(errors, printed_name)
    puts(colorize(msg))

    raise ContractError, msg
  end

  private

  def colorize(str)
    "\e[31m#{str}\e[0m"
  end

  def error_message(errors, printed_name)
    msgs = ["Contract violation for #{printed_name}"]

    errors.each do |name, cont, val|
      validator = Validators.fetch_for(cont)
      msg = validator.message(val, name)
      sps = msg.lines.one? ? ' ' : ''
      msgs << "\t - #{name}:#{sps}#{msg}"
    end

    msgs.join("\n")
  end
end
