# frozen_string_literal: true

require 'date'

class ReeMapper::DateTime < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => DateTime).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.class == DateTime
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a datetime, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, location: nil)
    if value.class == DateTime
      value
    elsif value.class == Time
      ReeDatetime::InDefaultTimeZone.new.call(value.to_datetime)
    elsif value.is_a?(String)
      begin
        ReeDatetime::InDefaultTimeZone.new.call(DateTime.parse(value))
      rescue ArgumentError
        raise ReeMapper::CoercionError.new("`#{name}` is invalid datetime, got `#{truncate(value.inspect)}`", location)
      end
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a datetime, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => DateTime).throws(ReeMapper::TypeError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
