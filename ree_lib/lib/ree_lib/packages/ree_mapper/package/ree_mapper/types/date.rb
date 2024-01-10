# frozen_string_literal: true

require 'date'

class ReeMapper::Date < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.class == Date
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a date, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def cast(value, name:, role: nil)
    if value.class == Date
      value
    elsif value.class == DateTime || value.class == Time
      value.to_date
    elsif value.is_a?(String)
      begin
        Date.parse(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError, "`#{name}` is invalid date, got `#{truncate(value.inspect)}`"
      end
    else
      raise ReeMapper::TypeError, "`#{name}` should be a date, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Date).throws(ReeMapper::TypeError, ReeMapper::CoercionError)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
