# frozen_string_literal: true
require_relative "base_enum_mapper"

class ReeEnum::IntegerValueEnumMapper < ReeEnum::BaseEnumMapper
  contract(
    ReeEnum::Value,
    Kwargs[
      name: String,
      role: Nilor[Symbol, ArrayOf[Symbol]]
    ] => Integer
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
    when Integer
      @enum.get_values.by_value(value)
    when String
      value = Integer(value, exception: false)
      if !value.nil?
        @enum.get_values.by_value(value)
      end
    when ReeEnum::Value
      @enum.get_values.each.find { _1 == value }
    end

    if enum_value.nil?
      raise ReeMapper::CoercionError, "`#{name}` should be one of #{enum_inspection}"
    end

    enum_value
  end
end