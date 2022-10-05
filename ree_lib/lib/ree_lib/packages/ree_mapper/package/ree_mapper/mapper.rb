# frozen_string_literal: true

class ReeMapper::Mapper
  contract(ArrayOf[ReeMapper::MapperStrategy], Nilor[ReeMapper::AbstractType] => Any)
  def self.build(strategies, type = nil)
    if type
      strategies.each do |strategy|
        method = strategy.method
        next if type.respond_to?(method)
        raise ReeMapper::UnsupportedTypeError, "type #{type.name} should implement method `#{method}`"
      end
    end

    klass = Class.new(self)

    klass.instance_eval do
      strategies.each do |strategy|
        method = strategy.method

        if type
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(obj, name: nil, role: nil)
              @type.#{method}(obj, name: name, role: role)
            end
          RUBY
        else
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(obj, name: nil, role: nil)
              @fields.each_with_object(@#{method}_strategy.build_object) do |(_, field), acc|
                next unless field.has_role?(role)
                nested_name = name ? "\#{name}[\#{field.name_as_str}]" : field.name_as_str

                is_with_value = @#{method}_strategy.has_value?(obj, field)
                is_optional = field.optional || @#{method}_strategy.always_optional

                if !is_with_value && !is_optional
                  raise ReeMapper::TypeError, "Missing required field `\#{field.from_as_str}` for `\#{name || 'root'}`"
                end

                next if !is_with_value && !field.has_default?

                value = if is_with_value
                  @#{method}_strategy.get_value(obj, field)
                else
                  field.default
                end

                unless value.nil? && field.null
                  value = field.type.#{method}(value, name: nested_name, role: role)
                end

                @#{method}_strategy.assign_value(acc, field, value)
              end
            end
          RUBY
        end
      end
    end

    klass.new(strategies, type)
  end

  attr_reader :strategies, :strategy_methods, :fields, :type

  def initialize(strategies, type)
    @fields = {}
    @type = type
    @strategies = strategies
    @strategy_methods = strategies.map(&:method)

    strategies.each do |strategy|
      method = strategy.method
      instance_variable_set(:"@#{method}_strategy", strategy)
    end
  end

  contract(Any, Symbol, Ksplat[RestKeys => Any] => nil)
  def add_field(type, name, **opts)
    @fields[name] = ReeMapper::Field.new(type, name, **opts)
    nil
  end

  contract(None => Nilor[Symbol])
  def name
    @name
  end

  contract(Symbol => Symbol)
  def name=(name)
    @name = name
  end
end
