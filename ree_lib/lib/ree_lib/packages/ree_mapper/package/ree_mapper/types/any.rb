# frozen_string_literal: true

class ReeMapper::Any < ReeMapper::AbstractType
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
