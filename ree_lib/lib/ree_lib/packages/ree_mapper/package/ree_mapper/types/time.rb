# frozen_string_literal: true

require 'time'

class ReeMapper::Time < ReeMapper::AbstractType
  contract(Any => Time).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.class == Time
      value
    else
      raise ReeMapper::TypeError.new("should be a time, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Time).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value)
    if value.class == Time
      value
    elsif value.class == DateTime
      value.to_time
    elsif value.is_a?(String)
      begin
        Time.parse(value)
      rescue ArgumentError
        raise ReeMapper::CoercionError.new("is invalid time, got `#{truncate(value.inspect)}`")
      end
    else
      raise ReeMapper::TypeError.new("should be a time, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Time).throws(ReeMapper::TypeError)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => Time).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value)
    cast(value)
  end
end
