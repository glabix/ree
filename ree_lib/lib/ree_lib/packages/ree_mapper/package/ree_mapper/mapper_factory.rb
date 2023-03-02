# frozen_string_literal: true

class ReeMapper::MapperFactory
  class << self
    attr_reader :types, :strategies
  end

  contract(Symbol => Nilor[ReeMapper::MapperStrategy])
  def self.find_strategy(strategy_method)
    strategies.detect { _1.method == strategy_method }
  end

  contract(Symbol, ReeMapper::AbstractType, Kwargs[strategies: ArrayOf[ReeMapper::MapperStrategy]] => Class)
  def self.register_type(name, object_type, strategies: self.strategies)
    register(
      name,
      ReeMapper::Mapper.build(strategies, object_type)
    )
  end

  contract(Symbol, ReeMapper::Mapper => Class).throws(ArgumentError)
  def self.register(name, type)
    raise ArgumentError, "name of mapper type should not end with `?`" if name.to_s.end_with?('?')

    defined_strategy_method = types[name]&.flat_map(&:strategies)&.map(&:method)&.detect { type.find_strategy(_1) }
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
        raise ArgumentError, "array item can't be optional" if field_name.nil? && optional

        type = self.class.types.fetch(:#{name}).detect { (@mapper.strategy_methods - _1.strategy_methods).empty? }

        unless type
          raise ReeMapper::UnsupportedTypeError, "type :#{name} should implement `\#{@mapper.strategy_methods.join(', ')}`"
        end

        return ReeMapper::Field.new(type, optional: optional, **opts) unless field_name

        @mapper.add_field(type, field_name, optional: optional, **opts)
      end

      def #{name}?(field_name, **opts)
        #{name}(field_name, optional: true, **opts)
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

  contract(Nilor[Symbol], Kwargs[each: Nilor[ReeMapper::Field], optional: Bool, dto: Nilor[Class]], Ksplat[RestKeys => Any], Optblock => Nilor[ReeMapper::Field])
  def array(field_name = nil, each: nil, optional: false, dto: nil, **opts, &blk)
    raise ReeMapper::Error, "invalid DSL usage" unless @mapper
    raise ArgumentError, "array item can't be optional" if field_name.nil? && optional
    raise ArgumentError, 'array type should use either :each or :block' if each && blk || !each && !blk
    raise ArgumentError, 'array does not permit :dto without :block' if dto && !blk
    raise ArgumentError, 'array does not permit :only and :except keys' if opts.key?(:only) || opts.key?(:except)

    if blk
      each = ReeMapper::Field.new(
        hash_from_blk(dto: dto, &blk)
      )
    end

    type = ReeMapper::Mapper.build(@mapper.strategies, ReeMapper::Array.new(each))

    return ReeMapper::Field.new(type, optional: optional, **opts) unless field_name

    @mapper.add_field(type, field_name, optional: optional, **opts)
  end

  contract(Symbol, Kwargs[each: Nilor[ReeMapper::Field]], Ksplat[RestKeys => Any], Optblock => Nilor[ReeMapper::Field])
  def array?(field_name, each: nil, **opts, &blk)
    raise ArgumentError if opts.key?(:optional)

    array(field_name, each: each, optional: true, **opts, &blk)
  end

  contract(Symbol, Kwargs[dto: Nilor[Class]], Ksplat[RestKeys => Any], Block => nil)
  def hash(field_name, dto: nil, **opts, &blk)
    raise ReeMapper::Error, "invalid DSL usage" unless @mapper

    type = hash_from_blk(dto: dto, &blk)

    @mapper.add_field(type, field_name, **opts)
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
