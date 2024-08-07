class ReeDto::FieldMeta
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts

  NONE = Object.new.freeze

  attr_reader :name, :contract, :setter, :default

  contract Symbol, Any, Bool, Any => Any
  def initialize(name, contract, setter, default)
    @name = name
    @contract = contract
    @setter = setter
    @default = default
  end

  contract None => Bool
  def has_default?
    @default != NONE
  end
end
