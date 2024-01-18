# frozen_string_literal: true

class ReeMapper::Float < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => Float).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.is_a?(Float)
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a float, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, location: nil)
    if value.is_a?(Numeric)
      value.to_f
    elsif value.is_a?(String)
      begin
        Float(value)
      rescue ArgumentError => e
        raise ReeMapper::CoercionError.new("`#{name}` is invalid float, got `#{truncate(value.inspect)}`", location)
      end
    elsif defined?(BigDecimal) && value.is_a?(BigDecimal)
      value.to_f
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a float, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Float).throws(ReeMapper::CoercionError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, location: nil)
    cast(value, name: name, location: location)
  end
end
