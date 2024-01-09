# frozen_string_literal: true

require 'time'

class ReeMapper::Time < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Time).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.class == Time
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a time, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Time).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def cast(value, name:, role: nil)
    if value.class == Time
      value
    elsif value.class == DateTime
      value.to_time
    elsif value.is_a?(String)
      begin
        Time.parse(value)
      rescue ArgumentError
        raise ReeMapper::CoercionError, "`#{name}` is invalid time, got `#{truncate(value.inspect)}`"
      end
    else
      raise ReeMapper::TypeError, "`#{name}` should be a time, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Time).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Time).throws(ReeMapper::CoercionError, ReeMapper::TypeError)
  def db_load(value, name:, role: nil)
    cast(value, name: name, role: role)
  end
end
