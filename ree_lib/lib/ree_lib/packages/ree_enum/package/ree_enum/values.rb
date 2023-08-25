# frozen_string_literal: true

class ReeEnum::Values
  attr_reader :klass, :enum_name

  def initialize(klass, enum_name)
    @klass = klass
    @enum_name = enum_name
    @collection = []
    @collection_by_value = {}
    @collection_by_mapped_value = {}
  end

  def to_a
    @collection
  end

  def each(&)
    @collection.each(&)
  end

  contract(Or[Symbol, String] => Nilor[ReeEnum::Value])
  def by_value(value)
    @collection_by_value[value.to_s]
  end

  contract(Or[Symbol, String] => ReeEnum::Value).throws(ArgumentError)
  def by_value!(value)
    by_value(value) ||
      (raise ArgumentError.new("constant for value #{value.inspect} is not found in #{self.inspect}"))
  end

  contract(Or[Integer, String] => Nilor[ReeEnum::Value])
  def by_mapped_value(mapped_value)
    @collection_by_mapped_value[mapped_value]
  end

  contract(Or[Integer, String] => ReeEnum::Value).throws(ArgumentError)
  def by_mapped_value!(mapped_value)
    by_mapped_value(mapped_value) ||
      (raise ArgumentError.new("constant for value #{mapped_value.inspect} is not found in #{self.inspect}"))
  end

  def inspect
    @collection.map(&:inspect).inspect
  end

  contract(String, Or[Integer, String], Symbol => ReeEnum::Value)
  def add(value, mapped_value, method)
    if @collection.any? { _1.method == method }
      raise ArgumentError, "#{@klass}: method #{method.inspect} was already added"
    end

    if @collection_by_value.key?(value)
      raise ArgumentError, "#{@klass}: value #{value.inspect} was already added"
    end

    if @collection_by_mapped_value.key?(mapped_value)
      raise ArgumentError, "#{@klass}: mapped_value(#{mapped_value.inspect}) for #{value.inspect} was already added"
    end

    enum_value = ReeEnum::Value.new(
      @klass, @enum_name, value, mapped_value, method
    )

    @collection << enum_value
    @collection_by_value[value] = enum_value
    @collection_by_mapped_value[mapped_value] = enum_value

    enum_value
  end
end