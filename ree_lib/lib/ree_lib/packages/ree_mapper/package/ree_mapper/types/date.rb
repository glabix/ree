# frozen_string_literal: true

require 'date'

class ReeMapper::Date < ReeMapper::AbstractType
  contract(Any => Date).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.class == Date
      value
    else
      raise ReeMapper::TypeError.new("should be a date, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def cast(value)
    if value.class == Date
      value
    elsif value.class == DateTime || value.class == Time
      value.to_date
    elsif value.is_a?(String)
      begin
        Date.parse(value)
      rescue ArgumentError
        raise ReeMapper::CoercionError.new("is invalid date, got `#{truncate(value.inspect)}`")
      end
    else
      raise ReeMapper::TypeError.new("should be a date, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Date).throws(ReeMapper::TypeError)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def db_load(value)
    cast(value)
  end
end
