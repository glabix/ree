# frozen_string_literal: true

class ReeMapper::Rational < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => Rational).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.is_a?(Rational)
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a rational, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Rational).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, location: nil)
    if value.is_a?(Rational)
      value
    elsif value.is_a?(String)
      begin
        Rational(value)
      rescue ArgumentError, ZeroDivisionError
        raise ReeMapper::CoercionError.new("`#{name}` is invalid rational, got `#{truncate(value.inspect)}`", location)
      end
    elsif value.is_a?(Numeric)
      Rational(value)
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a rational, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => String)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location).to_s
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Rational)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
