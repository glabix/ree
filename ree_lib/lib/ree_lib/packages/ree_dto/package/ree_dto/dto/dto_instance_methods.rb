require_relative "./field_meta"

module ReeDto::DtoInstanceMethods
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

  contract None => Set
  def reset_changes
    @changed_fields = nil
  end

  contract Symbol => ReeDto::FieldMeta
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
        raise FieldNotSetError.new("field :#{name} not set for:#{self}")
      else
        @_attrs[name] = meta.default
      end
    end
  end

  contract None => Hash
  def attrs
    @_attrs
  end

  contract Symbol, Any => Any
  def set_attr(name, val)
    @_attrs[name] = val
  end

  contract Symbol, Any => Any
  def set_value(name, val)
    if has_value?(name)
      old = get_value(name)
      return if old == val
    end

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

  contract None => String
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

  contract None => String
  def inspect
    to_s
  end
end
