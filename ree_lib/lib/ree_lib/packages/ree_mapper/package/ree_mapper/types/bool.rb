# frozen_string_literal: true

class ReeMapper::Bool < ReeMapper::AbstractType
  TRUE_CAST_VALUES = ['1', 'true', 'on', 1, true].freeze
  FALSE_CAST_VALUES = ['0', 'false', 'off', 0, false].freeze

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value
    else
      raise ReeMapper::TypeError, 'should be a boolean'
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::CoercionError)
  def cast(value, role: nil)
    if TRUE_CAST_VALUES.include?(value)
      true
    elsif FALSE_CAST_VALUES.include?(value)
      false
    else
      raise ReeMapper::CoercionError, "should be a boolean"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Bool).throws(ReeMapper::CoercionError)
  def db_load(value, role: nil)
    cast(value, role: role)
  end
end
