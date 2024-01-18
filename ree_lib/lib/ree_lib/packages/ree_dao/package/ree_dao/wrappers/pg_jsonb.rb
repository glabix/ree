require "sequel/extensions/pg_json"

package_require("ree_object/functions/to_hash")

class ReeDao::PgJsonb < ReeMapper::AbstractWrapper
  contract(
    Any,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter],
      location: Nilor[String],
    ] => Or[
      Sequel::Postgres::JSONBHash,
      Sequel::Postgres::JSONBArray,
      Sequel::Postgres::JSONBInteger,
      Sequel::Postgres::JSONBTrue,
      Sequel::Postgres::JSONBFalse,
      Sequel::Postgres::JSONBString,
      Sequel::Postgres::JSONBFloat,
      Sequel::Postgres::JSONBNull
    ]
  ).throws(ReeMapper::TypeError)
  def db_dump(value, name:, role: nil, fields_filters: [], location: nil)
    value = subject.type.db_dump(
      value,
      name: name,
      role: role,
      fields_filters: fields_filters + [subject.fields_filter],
      location: subject.location,
    )

    begin
      Sequel.pg_jsonb_wrap(value)
    rescue Sequel::Error
      raise ReeMapper::TypeError.new("`#{name}` should be an jsonb primitive, got `#{truncate(value.inspect)}`", location)
    end
  end

  contract(
    Any,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter],
      location: Nilor[String],
    ] => Or[
      Hash,
      Array,
      Integer,
      Float,
      String,
      Bool,
      NilClass,
      Rational,
    ]
  ).throws(ReeMapper::TypeError)
  def db_load(value, name:, role: nil, fields_filters: [], location: nil)
    value = case value
    when Sequel::Postgres::JSONBHash
      ReeObject::ToHash.new.call(value.to_h)
    when Sequel::Postgres::JSONBArray
      ReeObject::ToHash.new.call(value.to_a)
    when Numeric, String, TrueClass, FalseClass, NilClass
      value
    else
      raise ReeMapper::TypeError.new("`#{name}` should be a Sequel::Postgres::JSONB, got `#{truncate(value.inspect)}`", location)
    end

    subject.type.db_load(
      value,
      name: name,
      role: role,
      fields_filters: fields_filters + [subject.fields_filter],
      location: subject.location,
    )
  end
end