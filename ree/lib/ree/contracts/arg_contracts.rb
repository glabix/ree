# frozen_string_literal: true

module Ree::Contracts
  module ArgContracts
    autoload :Any, 'ree/contracts/arg_contracts/any'
    autoload :ArrayOf, 'ree/contracts/arg_contracts/array_of'
    autoload :Block, 'ree/contracts/arg_contracts/block'
    autoload :Bool, 'ree/contracts/arg_contracts/bool'
    autoload :Eq, 'ree/contracts/arg_contracts/eq'
    autoload :Exactly, 'ree/contracts/arg_contracts/exactly'
    autoload :HashOf, 'ree/contracts/arg_contracts/hash_of'
    autoload :Ksplat, 'ree/contracts/arg_contracts/ksplat'
    autoload :Kwargs, 'ree/contracts/arg_contracts/kwargs'
    autoload :Nilor, 'ree/contracts/arg_contracts/nilor'
    autoload :None, 'ree/contracts/arg_contracts/none'
    autoload :Optblock, 'ree/contracts/arg_contracts/optblock'
    autoload :Or, 'ree/contracts/arg_contracts/or'
    autoload :RangeOf, 'ree/contracts/arg_contracts/range_of'
    autoload :RespondTo, 'ree/contracts/arg_contracts/respond_to'
    autoload :SetOf, 'ree/contracts/arg_contracts/set_of'
    autoload :Splat, 'ree/contracts/arg_contracts/splat'
    autoload :SplatOf, 'ree/contracts/arg_contracts/splat_of'
    autoload :Squarable, 'ree/contracts/arg_contracts/squarable'
    autoload :SubclassOf, 'ree/contracts/arg_contracts/subclass_of'

    def self.opt_or_block?(contract)
      contract == Block || contract == Optblock
    end
  end
end
