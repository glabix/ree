# frozen_string_literal: true
require_relative "value"

class ReeEnum::BaseEnumMapper < ReeMapper::AbstractType
  attr_reader :enum

  def initialize(enum)
    @enum = enum
  end

  contract(
    ReeEnum::Value,
    Kwargs[
      name: String,
      location: Nilor[String],
    ] => Or[Integer, String]
  )
  def db_dump(value, name:, location: nil)
    value.mapped_value
  end

  contract(
    Or[Integer, String],
    Kwargs[
      name: String,
      location: Nilor[String],
    ] => ReeEnum::Value
  ).throws(ReeMapper::CoercionError)
  def db_load(value, name:, location: nil)
    enum_val = @enum.get_values.by_mapped_value(value)

    if !enum_val
      raise ReeMapper::CoercionError.new("`#{name}` should be one of #{enum_inspection}, got `#{truncate(value.inspect)}`", location)
    end

    enum_val
  end

  private

  def enum_inspection
    @enum_inspection ||= truncate(@enum.get_values.each.map(&:to_s).inspect)
  end
end