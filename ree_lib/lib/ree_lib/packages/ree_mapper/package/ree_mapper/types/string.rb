# frozen_string_literal: true

class ReeMapper::String < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def serialize(value, name:, role: nil)
    if value.is_a? String
      value
    else
      raise ReeMapper::TypeError, "`#{name}` should be a string, got `#{truncate(value.inspect)}`"
    end
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def cast(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => String).throws(ReeMapper::TypeError)
  def db_load(value, name:, role: nil)
    serialize(value, name: name, role: role)
  end
end
