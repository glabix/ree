require "sequel/extensions/pg_json"

package_require("ree_object/functions/to_hash")

class ReeDao::PgJsonb < ReeMapper::AbstractWrapper
  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: Nilor[ArrayOf[ReeMapper::FieldsFilter]],
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
  def db_dump(value, role: nil, fields_filters: nil)
    if subject.fields_filter
      fields_filters = if fields_filters
        fields_filters + [subject.fields_filter]
      else
        [subject.fields_filter]
      end
    end

    value = begin
      subject.type.db_dump(value, role:, fields_filters:)
    rescue ReeMapper::ErrorWithLocation => e
      e.location ||= subject.location
      raise e
    end

    begin
      Sequel.pg_jsonb_wrap(value)
    rescue Sequel::Error
      raise ReeMapper::TypeError.new("should be an jsonb primitive, got `#{truncate(value.inspect)}`")
    end
  end

  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: Nilor[ArrayOf[ReeMapper::FieldsFilter]],
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
  def db_load(value, role: nil, fields_filters: nil)
    value = case value
    when Sequel::Postgres::JSONBHash
      ReeObject::ToHash.new.call(value.to_h)
    when Sequel::Postgres::JSONBArray
      ReeObject::ToHash.new.call(value.to_a)
    when Numeric, String, TrueClass, FalseClass, NilClass
      value
    else
      raise ReeMapper::TypeError.new("should be a Sequel::Postgres::JSONB, got `#{truncate(value.inspect)}`")
    end

    if subject.fields_filter
      fields_filters = if fields_filters
        fields_filters + [subject.fields_filter]
      else
        [subject.fields_filter]
      end
    end

    begin
      subject.type.db_load(value, role:, fields_filters:)
    rescue ReeMapper::ErrorWithLocation => e
      e.location ||= subject.location
      raise e
    end
  end
end
