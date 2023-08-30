# frozen_string_literal: true

class ReeEnum::Value
  attr_reader :enum_class, :enum_name, :value, :method, :mapped_value

  contract(Class, Symbol, Or[String, Integer], Or[Integer, String], Symbol => Any)
  def initialize(enum_class, enum_name, value, mapped_value, method)
    @enum_class = enum_class
    @enum_name = enum_name
    @value = value
    @method = method
    @mapped_value = mapped_value
  end

  def to_s
    value.to_s
  end

  def as_json(*args)
    value
  end

  contract(Or[ReeEnum::Value, String, Symbol, Integer, Any] => Bool)
  def ==(compare)
    if compare.is_a?(self.class)
      value == compare.value
    elsif compare.is_a?(Symbol) && value.is_a?(String)
      value.to_sym == compare
    else
      value == compare || mapped_value == compare
    end
  end

  def inspect
    "#{enum_class.name}##{value}"
  end
end