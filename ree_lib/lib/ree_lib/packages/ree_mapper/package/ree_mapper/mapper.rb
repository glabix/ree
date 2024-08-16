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
            def #{method}(obj, role: nil, only: nil, except: nil, fields_filters: nil)
              #{
                if type.is_a?(ReeMapper::AbstractWrapper)
                  "@type.#{method}(obj, role:, fields_filters:)"
                else
                  "@type.#{method}(obj)"
                end
              }
            end
          RUBY
        else
          class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
            def #{method}(obj, role: nil, only: nil, except: nil, fields_filters: nil)
              user_fields_filter = ReeMapper::FieldsFilter.build(only, except)

              if !user_fields_filter.nil?
                fields_filters = if fields_filters.nil?
                  [user_fields_filter]
                else
                  fields_filters + [user_fields_filter]
                end
              end

              @fields.each_with_object(@#{method}_strategy.build_object) do |(_, field), acc|
                next unless fields_filters.nil? || fields_filters.all? { _1.allow? field.name }
                next unless field.has_role?(role)

                value = if @#{method}_strategy.has_value?(obj, field)
                  @#{method}_strategy.get_value(obj, field)
                else
                  if !field.optional && !@#{method}_strategy.always_optional
                    raise ReeMapper::TypeError.new(
                      "is missing (required field)",
                      field.location,
                      [field.from_as_str]
                    )
                  end

                  next unless field.has_default?

                  field.default
                end

                if !value.nil? || !field.null
                  nested_fields_filters = fields_filters&.filter_map { _1.filter_for(field.name) }

                  if field.fields_filter
                    nested_fields_filters = if nested_fields_filters
                      nested_fields_filters + [field.fields_filter]
                    else
                      [field.fields_filter]
                    end
                  end

                  value = begin
                    field.type.#{method}(value, role:, fields_filters: nested_fields_filters)
                  rescue ReeMapper::ErrorWithLocation => e
                    e.prepend_field_name field.name_as_str
                    e.location ||= field.location
                    raise e
                  end
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
