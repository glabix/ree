# frozen_string_literal: true
require_relative "base_enum_mapper"

class ReeEnum::StringValueEnumMapper < ReeEnum::BaseEnumMapper
  contract(
    ReeEnum::Value,
    Kwargs[
      name: String,
      location: Nilor[String],
    ] => String
  )
  def serialize(value, name:, location: nil)
    value.value
  end

  contract(
    Any,
    Kwargs[
      name: String,
      location: Nilor[String],
    ] => ReeEnum::Value
  ).throws(ReeMapper::CoercionError)
  def cast(value, name:, location: nil)
    enum_value = case value
    when String
      @enum.get_values.by_value(value)
    when ReeEnum::Value
      @enum.get_values.each.find { _1 == value }
    end

    if enum_value.nil?
      raise ReeMapper::CoercionError.new("`#{name}` should be one of #{enum_inspection}, got `#{truncate(value.inspect)}`", location)
    end

    enum_value
  end
end