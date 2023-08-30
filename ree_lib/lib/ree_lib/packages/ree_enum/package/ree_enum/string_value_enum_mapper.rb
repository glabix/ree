# frozen_string_literal: true
require_relative "base_enum_mapper"

class ReeEnum::StringValueEnumMapper < ReeEnum::BaseEnumMapper
  contract(
    ReeEnum::Value,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]]
    ] => String
  )
  def serialize(value, name:, role: nil)
    value.value
  end

  contract(
    Any,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]]
    ] => ReeEnum::Value
  ).throws(ReeMapper::CoercionError)
  def cast(value, name:, role: nil)
    enum_value = case value
    when String
      @enum.get_values.by_value(value)
    when ReeEnum::Value
      @enum.get_values.each.find { _1 == value }
    end

    if enum_value.nil?
      raise ReeMapper::CoercionError, "`#{name}` should be one of #{enum_inspection}"
    end

    enum_value
  end
end