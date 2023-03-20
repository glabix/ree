# frozen_string_literal: true

class ReeMapper::MapperFactory
  class << self
    attr_reader :types, :strategies, :wrappers
  end

  contract(Symbol => Nilor[ReeMapper::MapperStrategy])
  def self.find_strategy(strategy_method)
    strategies.detect { _1.method == strategy_method }
  end

  contract(Symbol, ReeMapper::AbstractType, Kwargs[strategies: ArrayOf[ReeMapper::MapperStrategy]] => Class)
  def self.register_type(name, object_type, strategies: self.strategies)
    register_mapper(
      name,
      ReeMapper::Mapper.build(strategies, object_type)
    )
  end

  contract(Symbol, ReeMapper::Mapper => SubclassOf[self]).throws(ArgumentError)
  def self.register_mapper(name, type)
    raise ArgumentError, "mapper registration name should not end with `?`" if name.to_s.end_with?('?')

    defined_strategy_method = types[name]&.flat_map(&:strategy_methods)&.detect { type.find_strategy(_1) }
    raise ArgumentError, "type :#{name} with `#{defined_strategy_method}` strategy already registered" if defined_strategy_method
    raise ArgumentError, "method :#{name} already defined" if !types.key?(name) && method_defined?(name)

    type = type.dup
    type.name = name
    type.freeze
    types[name] ||= []
    types[name] << type

    class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
      def #{name}(field_name = nil, optional: false, **opts)
        raise ReeMapper::Error, "invalid DSL usage" unless @mapper
        raise ArgumentError, "wrapped item can't be optional" if field_name.nil? && optional

        type = self.class.types.fetch(:#{name}).detect { (@mapper.strategy_methods - _1.strategy_methods).empty? }

        unless type
          raise ReeMapper::UnsupportedTypeError, "type :#{name} should implement `\#{@mapper.strategy_methods.join(', ')}`"
        end

        field = ReeMapper::Field.new(type, field_name, optional: optional, **opts)

        return field unless field_name

        @mapper.add_field(field)
      end

      def #{name}?(field_name, **opts)
        #{name}(field_name, optional: true, **opts)
      end
    RUBY

    self
  end

  contract(Symbol, SubclassOf[ReeMapper::AbstractWrapper] => SubclassOf[self])
  def self.register_wrapper(name, wrapper)
    raise ArgumentError, "wrapper registration name should not end with `?`" if name.to_s.end_with?('?')

    defined_strategy_method = wrappers[name]&.flat_map(&:strategy_methods)&.detect { wrapper.find_strategy(_1) }
    raise ArgumentError, "wrapper :#{name} with `#{defined_strategy_method}` strategy already registered" if defined_strategy_method
    raise ArgumentError, "method :#{name} already defined" if !types.key?(name) && !wrappers.key?(name) && method_defined?(name)

    wrappers[name] ||= []
    wrappers[name] << wrapper

    class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
      contract(
        Nilor[Symbol, ReeMapper::Field],
        Nilor[ReeMapper::Field],
        Kwargs[optional: Bool, dto: Nilor[Class]],
        Ksplat[RestKeys => Any],
        Optblock => Nilor[ReeMapper::Field]
      ).throws(ReeMapper::Error, ArgumentError, ReeMapper::UnsupportedTypeError)
      def #{name}(field_name = nil, subject = nil, optional: false, dto: nil, **opts, &blk)
        raise ReeMapper::Error, "invalid DSL usage" unless @mapper
        raise ArgumentError, 'wrapped type does not permit :dto without :block' if dto && !blk

        if field_name.is_a?(ReeMapper::Field)
          raise ArgumentError, "field_name should be a Symbol" if subject

          subject = field_name
          field_name = nil
        end

        raise ArgumentError, "wrapped item can't be optional" if field_name.nil? && optional
        raise ArgumentError, "wrapped type should use either :subject or :block" if subject && blk || !subject && !blk

        if blk
          subject = ReeMapper::Field.new(
            hash_from_blk(dto: dto, &blk)
          )
        end

        wrapper = self.class.wrappers.fetch(:#{name}).detect do |wrapper|
          @mapper.strategy_methods.all? { wrapper.method_defined?(_1) }
        end

        unless wrapper
          raise ReeMapper::UnsupportedTypeError, "wrapper :#{name} should implement `\#{@mapper.strategy_methods.join(', ')}`"
        end

        type = ReeMapper::Mapper.build(@mapper.strategies, wrapper.new(subject))
        type.name = :#{name}

        field = ReeMapper::Field.new(type, field_name, optional: optional, **opts)

        return field unless field_name

        @mapper.add_field(field)
      end

      def #{name}?(*args, **opts, &blk)
        #{name}(*args, optional: true, **opts, &blk)
      end
    RUBY

    self
  end

  contract(
    Kwargs[
      register_as: Nilor[Symbol]
    ],
    Optblock => ReeMapper::MapperFactoryProxy).throws(ArgumentError
  )
  def self.call(register_as: nil, &blk)
    ReeMapper::MapperFactoryProxy.new(self, register_as: register_as, &blk)
  end

  contract(ReeMapper::Mapper => Any)
  def initialize(mapper)
    @mapper = mapper
  end

  contract(Symbol, Kwargs[dto: Nilor[Class]], Ksplat[RestKeys => Any], Block => nil)
  def hash(field_name, dto: nil, **opts, &blk)
    raise ReeMapper::Error, "invalid DSL usage" unless @mapper

    type = hash_from_blk(dto: dto, &blk)

    field = ReeMapper::Field.new(type, field_name, **opts)

    @mapper.add_field(field)
  end

  contract(Symbol, Ksplat[RestKeys => Any], Block => nil)
  def hash?(field_name, **opts, &blk)
    hash(field_name, optional: true, **opts, &blk)
  end

  private

  def hash_from_blk(dto:, &blk)
    mapper_proxy = self.class.call

    strategies = @mapper.strategies.map do |strategy|
      strategy = strategy.dup
      strategy.dto = dto if dto
      strategy
    end

    strategies[0..-2].each do |strategy|
      mapper_proxy.use(strategy)
    end

    _hsh_mapper = mapper_proxy.use(strategies.last, &blk)
  end
end
