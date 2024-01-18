# frozen_string_literal: true

class ReeMapper::Integer < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => Integer).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.is_a? Integer
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be an integer, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, location: nil)
    if value.is_a?(Integer)
      value
    elsif value.is_a?(String)
      coerced_value = Integer(value, exception: false)
      if coerced_value.nil?
        raise ReeMapper::CoercionError.new("`#{name}` is invalid integer, got `#{truncate(value.inspect)}`", location)
      end
      coerced_value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be an integer, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Integer).throws(ReeMapper::TypeError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
