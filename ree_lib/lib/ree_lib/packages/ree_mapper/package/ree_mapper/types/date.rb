# frozen_string_literal: true

require 'date'

class ReeMapper::Date < ReeMapper::AbstractType
  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.class == Date
      value
    else
      raise ReeMapper::TypeError, "should be a date"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def cast(value, role: nil)
    if value.class == Date
      value
    elsif value.class == DateTime || value.class == Time
      value.to_date
    elsif value.is_a?(String)
      begin
        Date.parse(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError, "is invalid date"
      end
    else
      raise ReeMapper::TypeError, "should be a date"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def db_load(value, role: nil)
    cast(value, role: role)
  end
end
