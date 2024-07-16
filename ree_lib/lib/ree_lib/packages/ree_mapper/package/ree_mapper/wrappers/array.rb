# frozen_string_literal: true

class ReeMapper::Array < ReeMapper::AbstractWrapper
  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter],
    ] => Array
  ).throws(ReeMapper::TypeError)
  def serialize(value, role: nil, fields_filters: [])
    if !value.is_a?(Array)
      raise ReeMapper::TypeError.new("should be an array, got `#{truncate(value.inspect)}`")
    end

    fields_filters += [subject.fields_filter]

    value.map.with_index do |item, idx|
      next nil if item.nil? && subject.null

      subject.type.serialize(
        item,
        role: role,
        fields_filters: fields_filters,
      )
    rescue ReeMapper::ErrorWithLocation => e
      e.prepend_field_name(idx.to_s)
      e.location ||= subject.location
      raise e
    end
  end

  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter],
    ] => Array
  ).throws(ReeMapper::TypeError)
  def cast(value, role: nil, fields_filters: [])
    if !value.is_a?(Array)
      raise ReeMapper::TypeError.new("should be an array, got `#{truncate(value.inspect)}`")
    end

    fields_filters += [subject.fields_filter]

    value.map.with_index do |item, idx|
      next nil if item.nil? && subject.null

      subject.type.cast(
        item,
        role: role,
        fields_filters: fields_filters,
      )
    rescue ReeMapper::ErrorWithLocation => e
      e.prepend_field_name(idx.to_s)
      e.location ||= subject.location
      raise e
    end
  end

  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter],
    ] => Array
  ).throws(ReeMapper::TypeError)
  def db_dump(value, role: nil, fields_filters: [])
    if !value.is_a?(Array)
      raise ReeMapper::TypeError.new("should be an array, got `#{truncate(value.inspect)}`")
    end

    value.map.with_index do |item, idx|
      next nil if item.nil? && subject.null

      subject.type.db_dump(
        item,
        role: role,
        fields_filters: fields_filters,
      )
    rescue ReeMapper::ErrorWithLocation => e
      e.prepend_field_name(idx.to_s)
      e.location ||= subject.location
      raise e
    end
  end

  contract(
    Any,
    Kwargs[
      role: Nilor[Symbol, ArrayOf[Symbol]],
      fields_filters: ArrayOf[ReeMapper::FieldsFilter],
    ] => Array
  ).throws(ReeMapper::TypeError)
  def db_load(value, role: nil, fields_filters: [])
    if !value.is_a?(Array)
      raise ReeMapper::TypeError.new("should be an array, got `#{truncate(value.inspect)}`")
    end

    value.map.with_index do |item, idx|
      next nil if item.nil? && subject.null

      subject.type.db_load(
        item,
        role: role,
        fields_filters: fields_filters,
      )
    rescue ReeMapper::ErrorWithLocation => e
      e.prepend_field_name(idx.to_s)
      e.location ||= subject.location
      raise e
    end
  end
end
