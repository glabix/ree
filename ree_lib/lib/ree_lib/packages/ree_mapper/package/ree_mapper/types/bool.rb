# frozen_string_literal: true

class ReeMapper::Bool < ReeMapper::AbstractType
  TRUE_CAST_VALUES = ['1', 'true', 'on', 1, true].freeze
  FALSE_CAST_VALUES = ['0', 'false', 'off', 0, false].freeze

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a boolean, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::CoercionError)
  def cast(value, name:, role: nil)
    if TRUE_CAST_VALUES.include?(value)
      true
    elsif FALSE_CAST_VALUES.include?(value)
      false
    else
      raise ReeMapper::CoercionError, "`#{name}` is invalid boolean, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::CoercionError)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
