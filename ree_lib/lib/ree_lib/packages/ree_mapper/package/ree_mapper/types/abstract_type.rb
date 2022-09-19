class ReeMapper::AbstractType
  def serialize(value, name:, role: nil)
    raise NotImplementedError
  end

  def cast(value, name:, role: nil)
    raise NotImplementedError
  end

  def db_dump(value, name:, role: nil)
    raise NotImplementedError
  end

  def db_load(value, name:, role: nil)
    raise NotImplementedError
  end
end
