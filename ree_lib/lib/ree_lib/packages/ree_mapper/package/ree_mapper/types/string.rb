# frozen_string_literal: true

class ReeMapper::String < ReeMapper::AbstractType
  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.is_a? String
      value
    else
      raise ReeMapper::TypeError, 'should be a string'
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def cast(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def db_load(value, role: nil)
    serialize(value, role: role)
  end
end
