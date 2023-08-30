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
      :setup_enum, :get_values, :get_enum_name, :val,
      :__ENCODING__, :__LINE__, :__FILE__, :BEGIN, :END,
      :alias, :and, :begin, :break, :case, :class, :def, :defined?,
      :do, :else, :elsif, :end, :ensure, :false, :for, :if, :in,
      :module, :next, :nil, :not, :or, :redo, :rescue, :retry, :return,
      :self, :super, :then, :true, :undef, :unless, :until, :when, :while, :yield
    ].freeze

    ALLOWED_VALUE_TO_METHOD_REGEXP = /^[a-z_]\w*[?!]?$/

    def setup_enum(enum_name)
      @values ||= ReeEnum::Values.new(self, enum_name)
    end

    def get_values
      @values
    end

    def get_enum_name
      @values&.enum_name
    end

    def val(value, mapped_value = nil, method: nil)
      value = value.to_s if value.is_a?(Symbol)
      mapped_value ||= value

      if method.nil? && value.is_a?(String) && value.match?(ALLOWED_VALUE_TO_METHOD_REGEXP)
        method = value.to_sym
      end

      if RESTRICTED_METHODS.include?(method)
        raise ArgumentError.new("#{method.inspect} is not allowed as enum method")
      end

      enum_value = @values.add(value, mapped_value, method)

      if !method.nil?
        class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
          def #{method}
            get_values.by_value(#{value.inspect}.freeze)
          end

          def self.#{method}
            get_values.by_value(#{value.inspect}.freeze)
          end
        RUBY
      end

      enum_value
    end
  end

  def get_values
    self.class.get_values
  end
end