# frozen_string_literal: true

class ReeMapper::Integer < ReeMapper::AbstractType
  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Integer).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.is_a? Integer
      value
    else
      raise ReeMapper::TypeError, 'should be an integer'
    end
  end

  contract(Any , Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]]=> Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, role: nil)
    if value.is_a?(Integer)
      value
    elsif value.is_a?(String)
      begin
        Integer(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError, "is invalid integer"
      end
    else
      raise ReeMapper::TypeError, "should be an integer"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Integer).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, role: nil)
    cast(value, role: role)
  end
end
