# frozen_string_literal: true

require_relative 'value'
require_relative 'values'
require_relative 'contractable'

module ReeEnum::Enumerable
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    include ReeEnum::Contractable

    RESTRICTED_METHODS = [
      :setup_enum, :get_values, :get_enum_name,
      :val, :self, :class, :alias
    ].freeze

    def setup_enum(enum_name)
      @values ||= ReeEnum::Values.new(self, enum_name)
    end

    def get_values
      @values
    end

    def get_enum_name
      @values&.enum_name
    end

    def val(value, mapped_value = value.to_s, method: value.to_sym)
      value = value.to_s

      if RESTRICTED_METHODS.include?(method)
        raise ArgumentError.new("#{method.inspect} is not allowed as enum method")
      end

      enum_value = @values.add(value, mapped_value, method)

      define_method(enum_value.method) do
        get_values.by_value(enum_value.value)
      end

      define_singleton_method(enum_value.method) do
        get_values.by_value(enum_value.value)
      end

      enum_value
    end
  end

  def get_values
    self.class.get_values
  end
end