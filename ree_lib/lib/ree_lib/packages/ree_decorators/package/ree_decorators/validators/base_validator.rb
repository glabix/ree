# frozen_string_literal: true

module ReeDecorators
  class BaseValidator
    include Ree::LinkDSL

    link :truncate, from: :ree_string

    attr_reader :contract

    def initialize(contract)
      @contract = contract
    end

    def to_s
      raise NotImplementedError
    end

    def call(value)
      raise NotImplementedError
    end

    private

    def pluralize(num, single, plural)
      num == 1 ? single : plural
    end
  end
end
