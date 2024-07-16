# frozen_string_literal: true

class ReeMapper::Bool < ReeMapper::AbstractType
  TRUE_CAST_VALUES = ['1', 'true', 'on', 1, true].freeze
  FALSE_CAST_VALUES = ['0', 'false', 'off', 0, false].freeze

  contract(Any => Bool).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value
    else
      raise ReeMapper::TypeError.new("should be a boolean, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Bool).throws(ReeMapper::CoercionError)
  def cast(value)
    if TRUE_CAST_VALUES.include?(value)
      true
    elsif FALSE_CAST_VALUES.include?(value)
      false
    else
      raise ReeMapper::CoercionError.new("is invalid boolean, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Bool)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => Bool)
  def db_load(value)
    cast(value)
  end
end
