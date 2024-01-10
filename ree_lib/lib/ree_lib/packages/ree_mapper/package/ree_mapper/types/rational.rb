# frozen_string_literal: true

class ReeMapper::Rational < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Rational).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.is_a?(Rational)
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a rational, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Rational).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, role: nil)
    if value.is_a?(Rational)
      value
    elsif value.is_a?(String)
      begin
        Rational(value)
      rescue ArgumentError, ZeroDivisionError => e
        raise ReeMapper::CoercionError, "`#{name}` is invalid rational, got `#{truncate(value.inspect)}`"
      end
    elsif value.is_a?(Numeric)
      Rational(value)
    else
      raise ReeMapper::TypeError, "`#{name}` should be a rational, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => String)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role).to_s
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Rational)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
