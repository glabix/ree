module ReeDecorators
  module ArgContracts
    autoload :Any, 'ree_decorators/arg_contracts/any'
    autoload :ArrayOf, 'ree_decorators/arg_contracts/array_of'
    autoload :Block, 'ree_decorators/arg_contracts/block'
    autoload :Bool, 'ree_decorators/arg_contracts/bool'
    autoload :Eq, 'ree_decorators/arg_contracts/eq'
    autoload :Exactly, 'ree_decorators/arg_contracts/exactly'
    autoload :HashOf, 'ree_decorators/arg_contracts/hash_of'
    autoload :RestKeys, 'ree_decorators/arg_contracts/rest_keys'
    autoload :Ksplat, 'ree_decorators/arg_contracts/ksplat'
    autoload :Kwargs, 'ree_decorators/arg_contracts/kwargs'
    autoload :Nilor, 'ree_decorators/arg_contracts/nilor'
    autoload :None, 'ree_decorators/arg_contracts/none'
    autoload :Optblock, 'ree_decorators/arg_contracts/optblock'
    autoload :Or, 'ree_decorators/arg_contracts/or'
    autoload :RangeOf, 'ree_decorators/arg_contracts/range_of'
    autoload :RespondTo, 'ree_decorators/arg_contracts/respond_to'
    autoload :SetOf, 'ree_decorators/arg_contracts/set_of'
    autoload :Splat, 'ree_decorators/arg_contracts/splat'
    autoload :SplatOf, 'ree_decorators/arg_contracts/splat_of'
    autoload :Squarable, 'ree_decorators/arg_contracts/squarable'
    autoload :SubclassOf, 'ree_decorators/arg_contracts/subclass_of'

    def self.block_or_optblock?(contract)
      contract == Block || contract == Optblock
    end
  end
end
