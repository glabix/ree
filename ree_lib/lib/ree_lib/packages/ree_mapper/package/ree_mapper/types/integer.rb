# frozen_string_literal: true

class ReeMapper::Integer < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Integer).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.is_a? Integer
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be an integer"
    end
  end

  contract(Any , Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]]=> Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, role: nil)
    if value.is_a?(Integer)
      value
    elsif value.is_a?(String)
      value = Integer(value, exception: false)
      if value.nil?
        raise ReeMapper::CoercionError, "`#{name}` is invalid integer"
      end
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be an integer"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Integer).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Integer).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
