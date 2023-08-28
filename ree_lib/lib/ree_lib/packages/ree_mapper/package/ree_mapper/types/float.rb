# frozen_string_literal: true

class ReeMapper::Float < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.is_a?(Float)
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a float"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, role: nil)
    if value.is_a?(Numeric)
      value.to_f
    elsif value.is_a?(String)
      begin
        Float(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError, "`#{name}` is invalid float"
      end
    elsif defined?(BigDecimal) && value.is_a?(BigDecimal)
      value.to_f
    else
      raise ReeMapper::TypeError, "`#{name}` should be a float"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::CoercionError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
