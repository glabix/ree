# frozen_string_literal: true

class ReeMapper::Any < ReeMapper::AbstractType
  def db_load_trusted_check(var)
    "true"
  end

  contract(Any => Any)
  def serialize(value)
    value
  end

  contract(Any => Any)
  def cast(value)
    value
  end

  contract(Any => Any)
  def db_dump(value)
    value
  end

  contract(Any => Any)
  def db_load(value)
    value
  end
end
