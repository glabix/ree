# frozen_string_literal: true

class ReeMapper::Integer < ReeMapper::AbstractType
  contract(Any => Integer).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.is_a? Integer
      value
    else
      raise ReeMapper::TypeError.new("should be an integer, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value)
    if value.is_a?(Integer)
      value
    elsif value.is_a?(String)
      coerced_value = Integer(value, exception: false)
      if coerced_value.nil?
        raise ReeMapper::CoercionError.new("is invalid integer, got `#{truncate(value.inspect)}`")
      end
      coerced_value
    else
      raise ReeMapper::TypeError.new("should be an integer, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Integer).throws(ReeMapper::TypeError)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value)
    cast(value)
  end
end
