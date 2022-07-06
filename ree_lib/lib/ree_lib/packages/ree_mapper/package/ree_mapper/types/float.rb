# frozen_string_literal: true

class ReeMapper::Float < ReeMapper::AbstractType
  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::TypeError)
  def serialize(value, role: nil)
    if value.is_a?(Float)
      value
    else
      raise ReeMapper::TypeError, 'should be a float'
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, role: nil)
    if value.is_a?(Float)
      value
    elsif value.is_a?(String)
      begin
        Float(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError, "is invalid float"
      end
    else
      raise ReeMapper::TypeError, "should be a float"
    end
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::CoercionError)
  def db_dump(value, role: nil)
    serialize(value, role: role)
  end

  contract(Any, Kwargs[role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, role: nil)
    cast(value, role: role)
  end
end
