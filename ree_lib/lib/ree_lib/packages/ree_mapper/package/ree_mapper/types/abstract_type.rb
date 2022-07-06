class ReeMapper::AbstractType
  def serialize(value, role: nil)
    raise NotImplementedError
  end

  def cast(value, role: nil)
    raise NotImplementedError
  end

  def db_dump(value, role: nil)
    raise NotImplementedError
  end

  def db_load(value, role: nil)
    raise NotImplementedError
  end
end
