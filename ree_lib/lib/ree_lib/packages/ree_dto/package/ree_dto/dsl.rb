# frozen_string_literal: true

module ReeDto::DSL
  def self.included(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  def self.extended(base)
    base.include(InstanceMethods)
    base.extend(ClassMethods)
  end

  class FieldMeta
    attr_reader :name, :contract, :setter, :default
    NONE = Object.new.freeze

    def initialize(name, contract, setter, default)
      @name = name
      @contract = contract
      @setter = setter
      @default = default
    end

    def has_default?
      @default != NONE
    end
  end

  module InstanceMethods
    include Ree::Contracts::Core
    include Ree::Contracts::ArgContracts

    FieldNotSetError = Class.new(ArgumentError)

    if ReeDto.debug_mode?
      contract Hash, Ksplat[RestKeys => Any] => Any
      def initialize(attrs = nil, **kwargs)
        @_attrs = attrs || kwargs
        list = self.class.fields.map(&:name)
        extra = attrs.keys - list

        if !extra.empty?
          puts("WARNING: #{self.class}.new does not have definition for #{extra.inspect} fields")
        end
      end
    else
      contract Hash, Ksplat[RestKeys => Any] => Any
      def initialize(attrs = nil, **kwargs)
        @_attrs = attrs || kwargs
      end
    end

    contract Symbol => FieldMeta
    def get_meta(name)
      self
        .class
        .fields
        .find { _1.name == name} || (raise ArgumentError.new("field :#{name} not defined for :#{self.class}"))
    end

    contract Symbol => Any
    def get_value(name)
      @_attrs.fetch(name) do
        meta = get_meta(name)

        if !meta.has_default?
          raise FieldNotSetError.new("field :#{name} not set for #{self.class}")
        else
          @_attrs[name] = meta.default
        end
      end
    end

    def attrs
      @_attrs
    end

    contract Symbol, Any => Any
    def set_value(name, val)
      old = get_value(name)
      return if old == val

      @changed_fields ||= Set.new
      @changed_fields << name
      @_attrs[name] = val
    end

    contract Symbol => Bool
    def has_value?(name)
      @_attrs.key?(name) || get_meta(name).has_default?
    end

    contract None => ArrayOf[Symbol]
    def changed_fields
      @changed_fields&.to_a || []
    end

    contract Block => Any
    def each_field(&proc)
      self.class.fields.select { has_value?(_1.name) }.each do |field|
        proc.call(field.name, get_value(field.name))
      end
    end

    def to_s
      fields = self.class.fields
      max_length = fields.map(&:name).sort_by(&:size).last.size
      result     = "\n#{self.class}\n"

      data = fields.select { has_value?(_1.name) }.map do |field|
        name = field.name.to_s
        extra_spaces = ' ' * (max_length - name.size)
        %Q(  #{name}#{extra_spaces} = #{get_value(field.name).inspect})
      end

      result << data.join("\n")
    end

    def inspect
      to_s
    end
  end

  module ClassMethods
    include Ree::Contracts::Core
    include Ree::Contracts::ArgContracts

    def fields
      @fields ||= []
    end

    def build_dto(&proc)
      builder = DtoBuilder.new(self)
      builder.instance_exec(&proc)
      set_fields(builder.fields)

      builder.fields.each do |field|
        define_method field.name do
          get_value(field.name)
        end

        if field.setter
          define_method :"#{field.name}=" do |val|
            set_value(field.name, val)
          end
        end
      end
    end

    private

    class DtoBuilder
      attr_reader :fields

      def initialize(klass)
        @klass = klass
        @fields = []
      end

      def field(name, contract, setter: true, default: FieldMeta::NONE)
        existing = @fields.find { _1.name == name }

        if existing
          raise ArgumentError.new("field :#{name} already defined for #{klass}")
        end

        @fields.push << FieldMeta.new(name, contract, setter, default)
      end
    end

    def set_fields(v)
      @fields = v
    end
  end
end