class ReeDto::FieldMeta
  include Ree::Contracts::Core
  include Ree::Contracts::ArgContracts

  NONE = Object.new.freeze

  attr_reader :name, :contract, :setter, :default

  contract Symbol, Any, Bool, Any, Symbol => Any
  def initialize(name, contract, setter, default, field_type)
    @name = name
    @contract = contract
    @setter = setter
    @default = default
    @field_type = field_type
  end

  contract None => Bool
  def has_default?
    @default != NONE
  end
end
