# frozen_string_literal: true

class ReeMapper::Bool < ReeMapper::AbstractType
  TRUE_CAST_VALUES = ['1', 'true', 'on', 1, true].freeze
  FALSE_CAST_VALUES = ['0', 'false', 'off', 0, false].freeze

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Bool).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.is_a?(TrueClass) || value.is_a?(FalseClass)
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a boolean, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Bool).throws(ReeMapper::CoercionError)
  def cast(value, name:, location: nil)
    if TRUE_CAST_VALUES.include?(value)
      true
    elsif FALSE_CAST_VALUES.include?(value)
      false
    else
      raise ReeMapper::CoercionError.new("`#{name}` is invalid boolean, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Bool).throws(ReeMapper::TypeError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Bool).throws(ReeMapper::CoercionError)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
