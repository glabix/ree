require "sequel/extensions/pg_array"

class ReeDao::PgArray < ReeMapper::AbstractType
  def serialize(value, role: nil)
    raise ArgumentError.new("not supported")
  end

  def cast(value, role: nil)
    raise ArgumentError.new("not supported")
  end

  contract(
    ArrayOf[Any],
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]]
    ] => Sequel::Postgres::PGArray
  )
  def db_dump(value, role: nil)
    Sequel.pg_array(value)
  end

  contract(
    Sequel::Postgres::PGArray,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]]
    ] => ArrayOf[Any]
  ).throws(ReeMapper::TypeError)
  def db_load(value, role: nil)
    value.to_a
  end
end