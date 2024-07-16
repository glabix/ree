# frozen_string_literal: true

class ReeMapper::Rational < ReeMapper::AbstractType
  contract(Any => Rational).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.is_a?(Rational)
      value
    else
      raise ReeMapper::TypeError.new("should be a rational, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Rational).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value)
    if value.is_a?(Rational)
      value
    elsif value.is_a?(String)
      begin
        Rational(value)
      rescue ArgumentError, ZeroDivisionError
        raise ReeMapper::CoercionError.new("is invalid rational, got `#{truncate(value.inspect)}`")
      end
    elsif value.is_a?(Numeric)
      Rational(value)
    else
      raise ReeMapper::TypeError.new("should be a rational, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => String)
  def db_dump(value)
    serialize(value).to_s
  end

  contract(Any => Rational)
  def db_load(value)
    cast(value)
  end
end
