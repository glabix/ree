# frozen_string_literal: true

module Ree::Contracts
  class ProcValidator < BaseValidator
    def call(value)
      contract.call value
    end

    def to_s
      'Proc#call'
    end

    def message(value, name, lvl = 1)
      "proc validation failed for #{truncate(value.inspect)}"
    end
  end
end
