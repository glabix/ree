# frozen_string_literal: true

class ReeMapper::String < ReeMapper::AbstractType
  contract(Any => String).throws(ReeMapper::TypeError)
  def serialize(value)
    if value.is_a? String
      value
    else
      raise ReeMapper::TypeError.new("should be a string, got `#{truncate(value.inspect)}`")
    end
  end

  contract(Any => String).throws(ReeMapper::TypeError)
  def cast(value)
    serialize(value)
  end

  contract(Any => String).throws(ReeMapper::TypeError)
  def db_dump(value)
    serialize(value)
  end

  contract(Any => String).throws(ReeMapper::TypeError)
  def db_load(value)
    serialize(value)
  end
end
