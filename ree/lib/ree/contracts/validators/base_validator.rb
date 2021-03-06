# frozen_string_literal: true

module Ree::Contracts
  class BaseValidator
    include Ree::Contracts::Truncatable

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
