# frozen_string_literal: true

require "sequel/extensions/pg_array"

class ReeDao::PgArray < ReeMapper::AbstractWrapper
  contract(
    Any,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter]
    ] => Or[Sequel::Postgres::PGArray, String]
  )
  def db_dump(value, name:, role: nil, fields_filters: [])
    if !value.is_a?(Array)
      raise ReeMapper::TypeError, "`#{name}` should be an array"
    end

    value = value.map.with_index do |el, index|
      subject.type.db_dump(
        el,
        name: "#{name}[#{index}]",
        role: role,
        fields_filters: fields_filters + [subject.fields_filter]
      )
    end

    Sequel.pg_array(value)
  end

  contract(
    Any,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter]
    ] => Array
  ).throws(ReeMapper::TypeError)
  def db_load(value, name:, role: nil, fields_filters: [])
    if !value.is_a?(Sequel::Postgres::PGArray)
      raise ReeMapper::TypeError, "`#{name}` is not Sequel::Postgres::PGArray"
    end

    value.map.with_index do |val, index|
      subject.type.db_load(
        val,
        name: "#{name}[#{index}]",
        role: role,
        fields_filters: fields_filters + [subject.fields_filter]
      )
    end
  end
end
