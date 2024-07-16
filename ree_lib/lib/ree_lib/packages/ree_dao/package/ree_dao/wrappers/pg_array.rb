# frozen_string_literal: true

require "sequel/extensions/pg_array"

class ReeDao::PgArray < ReeMapper::AbstractWrapper
  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: Nilor[ArrayOf[ReeMapper::FieldsFilter]],
    ] => Or[Sequel::Postgres::PGArray, String]
  )
  def db_dump(value, role: nil, fields_filters: nil)
    if !value.is_a?(Array)
      raise ReeMapper::TypeError.new("should be an array, got `#{truncate(value.inspect)}`")
    end

    if subject.fields_filter
      fields_filters = if fields_filters
        fields_filters + [subject.fields_filter]
      else
        [subject.fields_filter]
      end
    end

    value = value.map.with_index do |item, idx|
      subject.type.db_dump(item, role:, fields_filters:)
    rescue ReeMapper::ErrorWithLocation => e
      e.location ||= subject.location
      e.prepend_field_name(idx.to_s)
      raise e
    end

    if value.empty?
      "{}"
    else
      Sequel.pg_array(value)
    end
  end

  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: Nilor[ArrayOf[ReeMapper::FieldsFilter]],
    ] => Array
  ).throws(ReeMapper::TypeError)
  def db_load(value, role: nil, fields_filters: nil)
    if !value.is_a?(Sequel::Postgres::PGArray)
      raise ReeMapper::TypeError.new("should be a Sequel::Postgres::PGArray, got `#{truncate(value.inspect)}`")
    end

    if subject.fields_filter
      fields_filters = if fields_filters
        fields_filters + [subject.fields_filter]
      else
        [subject.fields_filter]
      end
    end

    value.map.with_index do |item, idx|
      subject.type.db_load(item, role:, fields_filters:)
    rescue ReeMapper::ErrorWithLocation => e
      e.location ||= subject.location
      e.prepend_field_name(idx.to_s)
      raise e
    end
  end
end
