class ReeDto::CollectionMeta
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts

  attr_reader :name, :contract, :filter_proc

  contract Symbol, Any, Proc => Any
  def initialize(name, contract, filter_proc)
    @name = name
    @contract = contract
    @filter_proc = filter_proc
  end
end
