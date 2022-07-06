# frozen_string_literal: true

module Ree::Contracts
  class CalledArgsValidator
    class ArgContract < Struct.new(:type, :contract, :arg); end
    class Arg < Struct.new(:name, :type, :validator, :contract); end

    attr_reader :contracts, :block_contract, :params, :printed_name
    
    def initialize(contract, params, printed_name)
      @contracts = contract.arg_contracts
      @block_contract = contract.block_contract
      @params = params
      @printed_name = printed_name
      @args = {}
      build_args
    end

    def get_args
      @args
    end
    
    def get_arg(arg_name)
      @args[arg_name]
    end

    def call(args, kwargs, blk)
      if block_contract == ArgContracts::Block && !blk
        msg = "missing required block"
        raise ContractError, "Wrong number of arguments for #{printed_name}\n\t - #{msg}"
      end

      errors = []

      validate_args(args, errors)
      validate_kwargs(kwargs, errors)

      return if errors.empty?

      msg = error_message(errors)
      puts(colorize(msg))

      raise ContractError, msg
    end

    private

    def colorize(str)
      "\e[31m#{str}\e[0m"
    end

    def build_args
      ordinary_args = params.select { |type, _| type == :req || type == :opt }
      all_keyword_args = params.select { |type, _| type == :keyreq || type == :key }
      opt_keyword_args = params.select { |type, _| type == :key }
      ksplat_arg = params.detect { |type, _| type == :keyrest }
      splat_arg = params.detect { |type, _| type == :rest }

      kwarg_contract = contracts.detect { _1.is_a?(ArgContracts::Kwargs) }
      splat_contract = contracts.detect { _1.is_a?(ArgContracts::Splat) }
      ksplat_contract = contracts.detect { _1.is_a?(ArgContracts::Ksplat) }
      default_msg = "Contract definition mismatches method definition for #{printed_name}"

      @ksplat_contract = ksplat_contract
      @kwarg_contract = kwarg_contract

      if !opt_keyword_args.empty?
        if kwarg_contract.nil?
          msgs = [default_msg]
          msgs << "\t - methods with optional keyword arguments should use Kwargs[...] to describe all keyword args"
          raise BadContractError, msgs.join("\n")
        else
          missing_keys = all_keyword_args.map { _2 } - kwarg_contract.keys

          if !missing_keys.empty?
            msgs = [default_msg]

            missing_keys.each do |key|
              msgs << "\t - missing Kwargs contract for keyword argument `#{key}`"
            end
            raise BadContractError, msgs.join("\n")
          end
        end
      elsif kwarg_contract && all_keyword_args.empty?
        msgs = [default_msg]
        msgs << "\t - Kwargs contract should be used to describe keyword arguments only"
        raise BadContractError, msgs.join("\n")
      end
      
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
        msgs = [default_msg]
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

    def validate_kwargs(kwargs, errors)
      extra_keys = kwargs.keys - key_params.map { _1.last }

      if !extra_keys.empty? && !ksplat_arg
        msgs = []

        extra_keys.each do |key|
          msgs << "\t - unknown keyword arg `#{key}`"
        end

        raise ContractError, "Wrong number of arguments for #{printed_name}\n#{msgs.join("\n")}"
      end

      key_params.each do |type, name|
        if type == :keyreq && !kwargs.has_key?(name)
          msg = "missing keyword arg `#{name}`"
          raise ContractError, "Wrong number of arguments for #{printed_name}\n\t - #{msg}"
        end

        next if type == :key && !kwargs.has_key?(name)

        arg = @args.fetch(name)
        arg_value = kwargs.fetch(name)
        
        next if arg.validator.call(arg_value)

        errors << [name, arg.contract, arg_value]
      end

      if ksplat_arg && !extra_keys.empty?
        key = ksplat_arg.last
        arg = @args.fetch(key)
        value = {}

        extra_keys.each do |key|
          value.store(key, kwargs[key])
        end

        if !arg.validator.call(value)
          errors << [key, arg.contract, value]
        end
      end
    end

    def validate_args(args, errors)
      args = args.dup
      args_number = args.size
      assigned_args = {}
      
      # validate req args before opt/splat
      arg_params.each do |(type, name)|
        break if type != :req

        if args.size == 0
          msg = "missing value for `#{name}`"
          raise ContractError, "Wrong number of arguments for #{printed_name}\n\t - #{msg}"
        end

        assigned_args[name] = true
        arg_value = args.shift
        arg = @args[name]
        errors << [name, arg.contract, arg_value] unless arg.validator.call(arg_value)
      end

      # validate req args after opt/splat
      arg_params.reverse_each.with_index(1) do |(type, name), idx|
        break if type != :req
        break if assigned_args[name]

        if args.size == 0
          msg = "missing value for `#{name}`"
          raise ContractError, "Wrong number of arguments for #{printed_name}\n\t - #{msg}"
        end
        
        arg_value = args.pop
        arg = @args[name]
        errors << [name, arg.contract, arg_value] unless arg.validator.call(arg_value)
      end unless args.empty?

      # validate opt args
      arg_params.each_with_index do |(type, name), idx|
        break if args.empty?
        next if type != :opt

        arg_value = args.shift
        arg = @args[name]
        errors << [name, arg.contract, arg_value] unless arg.validator.call(arg_value)
      end

      if !splat_arg && args.size > 0
        msg = "given #{args_number}, expected #{arg_params.size}"
        raise ContractError, "Wrong number of arguments for #{printed_name}\n\t - #{msg}"
      end

      if splat_arg
        name = splat_arg.last
        arg = @args[name]
        errors << [name, arg.contract, args] unless arg.validator.call(args)
      end
    end

    def splat_arg
      @splat_arg ||= params.detect { |type, _| type == :rest }
    end

    def ksplat_arg
      @ksplat_arg ||= params.detect { |type, _| type == :keyrest }
    end

    def arg_params
      @arg_params ||= params.select { |type, _| type == :req || type == :opt }
    end

    def key_params
      @key_params ||= params.select { |type, _| type == :keyreq || type == :key }
    end

    def error_message(errors)
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
end
