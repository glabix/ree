# frozen_string_literal: true

class ReeMapper::Any < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Any)
  def serialize(value, name:, role: nil)
    value
  end

  contract(Any , Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Any)
  def cast(value, name:, role: nil)
    value
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Any)
  def db_dump(value, name:, role: nil)
    value
  end

  contract(Any, Kwargs[name: String, role: Nilor[Symbol, ArrayOf[Symbol]]] => Any)
  def db_load(value, name:, role: nil)
    value
  end
end
