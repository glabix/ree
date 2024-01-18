# frozen_string_literal: true

require 'time'

class ReeMapper::Time < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => Time).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.class == Time
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a time, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Time).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, location: nil)
    if value.class == Time
      value
    elsif value.class == DateTime
      value.to_time
    elsif value.is_a?(String)
      begin
        Time.parse(value)
      rescue ArgumentError
        raise ReeMapper::CoercionError.new("`#{name}` is invalid time, got `#{truncate(value.inspect)}`", location)
      end
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a time, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Time).throws(ReeMapper::TypeError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Time).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
