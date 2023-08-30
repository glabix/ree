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

  def value_type
    raise ArgumentError, "value_type is not defined" unless defined?(@value_type)
    @value_type
  end

  def to_a
    @collection
  end

  def each(&)
    @collection.each(&)
  end

  contract(Or[Symbol, String, Integer] => Nilor[ReeEnum::Value])
  def by_value(value)
    value = value.to_s if value.is_a?(Symbol)
    @collection_by_value[value]
  end

  contract(Or[Symbol, String, Integer] => ReeEnum::Value).throws(ArgumentError)
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

  contract(Or[String, Integer], Or[Integer, String], Nilor[Symbol] => ReeEnum::Value)
  def add(value, mapped_value, method)
    if @value_type.nil?
      @value_type = value.class
    elsif @value_type != value.class
      raise ArgumentError, "#{@klass}: value types should be the same for all enum values"
    end

    if !method.nil? && @collection.any? { _1.method == method }
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