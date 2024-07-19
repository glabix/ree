# frozen_string_literal: true

require 'date'

class ReeMapper::DateTime < ReeMapper::AbstractType
  contract(Any => DateTime).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.class == DateTime
      value
    else
      raise ReeMapper::TypeError.new("should be a datetime, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value)
    if value.class == DateTime
      value
    elsif value.class == Time
      ReeDatetime::InDefaultTimeZone.new.call(value.to_datetime)
    elsif value.is_a?(String)
      begin
        ReeDatetime::InDefaultTimeZone.new.call(DateTime.parse(value))
      rescue ArgumentError
        raise ReeMapper::CoercionError.new("is invalid datetime, got `#{truncate(value.inspect)}`")
      end
    else
      raise ReeMapper::TypeError.new("should be a datetime, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => DateTime)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => DateTime)
  def db_load(value)
    cast(value)
  end
end
