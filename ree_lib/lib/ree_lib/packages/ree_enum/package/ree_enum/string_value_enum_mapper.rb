# frozen_string_literal: true
require_relative "base_enum_mapper"

class ReeEnum::StringValueEnumMapper < ReeEnum::BaseEnumMapper
  contract(ReeEnum::Value => String)
  def serialize(value)
    value.value
  end

  contract(Any => ReeEnum::Value).throws(ReeMapper::CoercionError)
  def cast(value)
    enum_value = case value
    when String
      @enum.get_values.by_value(value)
    when ReeEnum::Value
      @enum.get_values.each.find { _1 == value }
    end

    if enum_value.nil?
      raise ReeMapper::CoercionError.new("should be one of #{enum_inspection}, got `#{truncate(value.inspect)}`")
    end

    enum_value
  end
end
