# frozen_string_literal: true

module ReeEnum::Contractable
  include Ree::Contracts::Truncatable

  def valid?(value)
    value.is_a?(ReeEnum::Value) && value.enum_name == self.get_enum_name && get_values.each.include?(value)
  end

  def message(value, name, lvl = 1)
    "expected one of #{self.name}, got #{value.class} => #{truncate(value.inspect)}"
  end
end
