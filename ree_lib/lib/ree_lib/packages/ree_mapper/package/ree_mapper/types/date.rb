# frozen_string_literal: true

require 'date'

class ReeMapper::Date < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => Date).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.class == Date
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a date, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def cast(value, name:, location: nil)
    if value.class == Date
      value
    elsif value.class == DateTime || value.class == Time
      value.to_date
    elsif value.is_a?(String)
      begin
        Date.parse(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError.new("`#{name}` is invalid date, got `#{truncate(value.inspect)}`", location)
      end
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a date, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Date).throws(ReeMapper::TypeError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
