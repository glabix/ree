# frozen_string_literal: true

class ReeMapper::Mapper
  contract(
    ArrayOf[ReeMapper::MapperStrategy],
    Nilor[ReeMapper::AbstractType, ReeMapper::AbstractWrapper] => self
  ).throws(ReeMapper::UnsupportedTypeError)
  def self.build(strategies, type = nil)
    if type
      strategies.each do |strategy|
        method = strategy.method
        next if type.respond_to?(method)

        raise ReeMapper::UnsupportedTypeError, "#{type.class} should implement method `#{method}`"
      end
    end

    klass = Class.new(self)

    klass.instance_eval do
      strategies.each do |strategy|
        method = strategy.method

        if type
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(obj, name: nil, role: nil, only: nil, except: nil, fields_filters: [], location: nil)
              #{
                if type.is_a?(ReeMapper::AbstractWrapper)
                  "@type.#{method}(obj, name: name, role: role, fields_filters: fields_filters, location: location)"
                else
                  "@type.#{method}(obj, name: name, location: location)"
                end
              }
            end
          RUBY
        else
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(obj, name: nil, role: nil, only: nil, except: nil, fields_filters: [], location: nil)
              if only && !ReeMapper::FilterFieldsContract.valid?(only)
                raise ReeMapper::ArgumentError, "Invalid `only` format"
              end

              if except && !ReeMapper::FilterFieldsContract.valid?(except)
                raise ReeMapper::ArgumentError, "Invalid `except` format"
              end

              user_fields_filter = ReeMapper::FieldsFilter.build(only: only, except: except)

              @fields.each_with_object(@#{method}_strategy.build_object) do |(_, field), acc|
                field_fields_filters = fields_filters + [user_fields_filter]

                next unless field_fields_filters.all? { _1.allow? field.name }
                next unless field.has_role?(role)

                is_with_value = @#{method}_strategy.has_value?(obj, field)
                is_optional = field.optional || @#{method}_strategy.always_optional

                if !is_with_value && !is_optional
                  raise ReeMapper::TypeError.new("Missing required field `\#{field.from_as_str}` for `\#{name || 'root'}`", field.location)
                end

                next if !is_with_value && !field.has_default?

                value = if is_with_value
                  @#{method}_strategy.get_value(obj, field)
                else
                  field.default
                end

                unless value.nil? && field.null
                  nested_name = name ? "\#{name}[\#{field.name_as_str}]" : field.name_as_str

                  nested_fields_filters = field_fields_filters.map { _1.filter_for(field.name) }
                  nested_fields_filters += [field.fields_filter]

                  value = field.type.#{method}(
                    value,
                    name: nested_name,
                    role: role,
                    fields_filters: nested_fields_filters,
                    location: field.location,
                  )
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

  contract(ReeMapper::Field => nil)
  def add_field(field)
    raise ArgumentError if field.name.nil?
    @fields[field.name] = field
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

  contract(Symbol => Class).throws(ArgumentError)
  def dto(strategy_method)
    strategy = find_strategy(strategy_method)
    raise ArgumentError, "there is no :#{strategy_method} strategy" unless strategy
    strategy.dto
  end

  contract(None => nil).throws(ReeMapper::ArgumentError)
  def prepare_dto
    raise ReeMapper::ArgumentError, "mapper should contain at least one field" if fields.empty?
    strategies.each { _1.prepare_dto(fields.keys) }
    nil
  end

  contract(Symbol => Nilor[ReeMapper::MapperStrategy])
  def find_strategy(strategy_method)
    strategies.detect { _1.method == strategy_method }
  end
end
