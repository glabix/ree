# frozen_string_literal: true

require 'date'

class ReeMapper::DateTime < ReeMapper::AbstractType
  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.class == DateTime
      value
    else
      raise ReeMapper::TypeError, "should be a datetime"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, role: nil)
    if value.class == DateTime
      value
    elsif value.class == Time
      ReeDatetime::InDefaultTimeZone.new.call(value.to_datetime)
    elsif value.is_a?(String)
      begin
        ReeDatetime::InDefaultTimeZone.new.call(DateTime.parse(value))
      rescue ArgumentError
        raise ReeMapper::CoercionError, "is invalid datetime"
      end
    else
      raise ReeMapper::TypeError, "should be a datetime"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, role: nil)
    cast(value, role: role)
  end
end
