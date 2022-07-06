# frozen_string_literal: true

require_relative 'value'
require_relative 'values'
require_relative 'contractable'

module ReeEnum::Enumerable
  module CommonMethods
    def by_value(value)
      values.by_value(value)
    end

    def by_number(number)
      values.by_number(number)
    end

    def all
      values.all
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    include ReeEnum::Contractable

    def setup_enum(enum_name)
      @values ||= ReeEnum::Values.new(self, enum_name)
    end

    def values
      @values
    end

    def enum_name
      return if !@values
      @values.enum_name
    end

    include CommonMethods

    def val(value, number, label = nil)
      if value == :new
        raise ArgumentError.new(":new is not allowed as enum value")
      end
      
      enum_value = values.add(value, number: number, label: label)

      define_method "#{enum_value.value}" do
        by_value(enum_value.value)
      end

      define_singleton_method "#{enum_value.value}" do
        by_value(enum_value.value)
      end

      enum_value
    end
  end

  def values
    self.class.values
  end

  include CommonMethods
end