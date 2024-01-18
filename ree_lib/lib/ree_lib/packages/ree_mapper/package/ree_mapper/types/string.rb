# frozen_string_literal: true

class ReeMapper::String < ReeMapper::AbstractType
  contract(Any, Kwargs[name: String, location: Nilor[String]] => String).throws(ReeMapper::TypeError)
  def serialize(value, name:, location: nil)
    if value.is_a? String
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a string, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => String).throws(ReeMapper::TypeError)
  def cast(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => String).throws(ReeMapper::TypeError)
  def db_dump(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end

  contract(Any, Kwargs[name: String, location: Nilor[String]] => String).throws(ReeMapper::TypeError)
  def db_load(value, name:, location: nil)
    serialize(value, name: name, location: location)
  end
end
