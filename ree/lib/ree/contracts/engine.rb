# frozen_string_literal: true

module Ree::Contracts
  class Engine
    class << self
      def fetch_for(target)
        engines[target.object_id] ||= new(target)
      end

      private

      def engines
        @engines ||= {}
      end
    end

    include Ree::Args

    attr_reader :target

    def initialize(target)
      check_arg_any(target, :target, [Class, Module])
      @target = target
    end

    def add_contract(*args)
      if @contract
        raise Ree::Error.new('Another active contract definition found', :invalid_dsl_usage)
      end

      @contract = ContractDefinition.new(args)
    end

    def add_doc(str)
      check_arg(str, :str, String)

      if @doc
        raise Ree::Error.new('Another active contract definition found', :invalid_dsl_usage)
      end

      @doc = str
    end

    def add_errors(*errors)
      if @errors
        raise Ree::Error.new('Another active contract definition found', :invalid_dsl_usage)
      end

      errors.each do |e|
        check_arg(e, :errors, Class)
      end

      @errors = errors
    end

    def fetch_doc
      doc, @doc = @doc, nil
      doc
    end

    def fetch_contract
      contract, @contract = @contract, nil
      contract
    end

    def fetch_errors
      errors, @errors = @errors, nil
      errors
    end
  end
end
