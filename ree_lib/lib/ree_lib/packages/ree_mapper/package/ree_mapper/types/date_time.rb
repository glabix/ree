# frozen_string_literal: true

require 'date'

class ReeMapper::DateTime < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.class == DateTime
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a datetime"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, role: nil)
    if value.class == DateTime
      value
    elsif value.class == Time
      ReeDatetime::InDefaultTimeZone.new.call(value.to_datetime)
    elsif value.is_a?(String)
      begin
        ReeDatetime::InDefaultTimeZone.new.call(DateTime.parse(value))
      rescue ArgumentError
        raise ReeMapper::CoercionError, "`#{name}` is invalid datetime"
      end
    else
      raise ReeMapper::TypeError, "`#{name}` should be a datetime"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => DateTime).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
