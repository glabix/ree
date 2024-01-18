# frozen_string_literal: true
require_relative "base_enum_mapper"

class ReeEnum::IntegerValueEnumMapper < ReeEnum::BaseEnumMapper
  contract(
    ReeEnum::Value,
    Kwargs[
      name: String,
      location: Nilor[String],
    ] => Integer
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
      raise ReeMapper::CoercionError.new("`#{name}` should be one of #{enum_inspection}, got `#{truncate(value.inspect)}`", location)
    end

    enum_value
  end
end