# frozen_string_literal: true

class ReeEnum::Values
  attr_reader :klass, :enum_name

  def initialize(klass, enum_name)
    @klass = klass
    @enum_name = enum_name
    @collection = {}
  end

  def all
    @collection.values.sort_by(&:number)
  end

  contract(Symbol => ReeEnum::Value).throws(ArgumentError)
  def by_value(value)
    type = @collection.values.detect {|c| c.value == value}
    type || (raise ArgumentError.new("constant for value #{value.inspect} is not found in #{self.inspect}"))
  end

  contract(Integer => ReeEnum::Value).throws(ArgumentError)
  def by_number(number)
    type = @collection.values.detect {|c| c.number == number}
    type || (raise ArgumentError.new("constant for value #{number.inspect} is not found in #{self.inspect}"))
  end

  def inspect
    @collection.values.map(&:inspect).inspect
  end

  contract(Symbol, Kwargs[number: Integer, label: Nilor[String]] => ReeEnum::Value)
  def add(value, number:, label: nil)
    if @collection.has_key?(value)
      raise ArgumentError, "#{@klass}: value #{value.inspect} was already added"
    end

    if @collection.values.any? {|v| v.number == number}
      raise ArgumentError, "number for #{value.inspect} was already added"
    end

    @collection[value] = ReeEnum::Value.new(
      @klass, @enum_name, value, number, label
    )
  end
end