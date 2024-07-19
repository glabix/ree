# frozen_string_literal: true

class ReeMapper::Float < ReeMapper::AbstractType
  contract(Any => Float).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.is_a?(Float)
      value
    else
      raise ReeMapper::TypeError.new("should be a float, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value)
    if value.is_a?(Numeric)
      value.to_f
    elsif value.is_a?(String)
      begin
        Float(value)
      rescue ArgumentError
        raise ReeMapper::CoercionError.new("is invalid float, got `#{truncate(value.inspect)}`")
      end
    elsif defined?(BigDecimal) && value.is_a?(BigDecimal)
      value.to_f
    else
      raise ReeMapper::TypeError.new("should be a float, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => Float).throws(ReeMapper::CoercionError)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => Float).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value)
    cast(value)
  end
end
