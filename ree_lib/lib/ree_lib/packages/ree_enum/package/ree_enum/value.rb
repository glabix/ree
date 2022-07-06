# frozen_string_literal: true

class ReeEnum::Value
  attr_reader :enum_class, :enum_name, :value, :label, :number

  contract(Class, Symbol, Symbol, Integer, Nilor[String] => Any)
  def initialize(enum_class, enum_name, value, number, label)
    @enum_class = enum_class
    @enum_name = enum_name
    @value = value
    @label = label
    @number = number
  end

  def to_s
    @value.to_s
  end

  def to_sym
    @value
  end

  def to_i
    @number
  end

  def as_json(*args)
    to_s
  end

  def label
    @label
  end

  contract(Or[ReeEnum::Value, Symbol, Integer, Any] => Bool)
  def ==(compare)
    if compare.is_a?(self.class)
      @value == compare.value
    else
      @value == compare || @number == compare
    end
  end

  contract(Or[ReeEnum::Value, String, Integer] => Bool)
  def <=>(other)
    if other.is_a?(self.class)
      @number <=> other.number
    elsif other.is_a?(Symbol)
      @value == other
    elsif other.is_a?(Integer)
      @number == other
    else
      raise ArgumentError.new("unable to compare ReeEnum::Value with other classes")
    end
  end
  
  def inspect
    "#{enum_class.name}##{@value.to_s}"
  end
end