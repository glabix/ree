# frozen_string_literal: true

class ReeMapper::Any < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => Any)
  def serialize(value, name:, location: nil)
    value
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Any)
  def cast(value, name:, location: nil)
    value
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Any)
  def db_dump(value, name:, location: nil)
    value
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => Any)
  def db_load(value, name:, location: nil)
    value
  end
end
