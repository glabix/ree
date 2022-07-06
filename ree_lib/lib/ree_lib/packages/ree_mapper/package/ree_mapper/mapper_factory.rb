# frozen_string_literal: true

class ReeMapper::MapperFactory
  class << self
    attr_reader :types, :strategies
  end

  HASH_KEY_OPTION_VALUES = [:symbol, :string, nil].freeze
  HASH_KEY_OPTION_MAP = {
    symbol: ReeMapper::SymbolKeyHashOutput,
    string: ReeMapper::StringKeyHashOutput
  }.freeze

  contract(Symbol, Any => Class).throws(ArgumentError)
  def self.register(name, type)
    raise ArgumentError, "name of mapper type should not include `?`" if name.to_s.end_with?('?')
    raise ArgumentError, "type :#{name} already registered" if types.key?(name)
    raise ArgumentError, "method :#{name} already defined" if method_defined?(name)

    type = type.dup
    type.name = name
    type.freeze
    types[name] = type

    class_eval(<<~RUBY, __FILE__, __LINE__ + 1)
      def #{name}(field_name = nil, optional: false, **opts)
        raise ReeMapper::Error, "invalid DSL usage" unless @mapper
        raise ArgumentError, "array item can't be optional" if field_name.nil? && optional

        type = self.class.types.fetch(:#{name})

        @mapper.strategy_methods.each do |method|
          next if type.respond_to?(method)
          raise ReeMapper::UnsupportedTypeError, "type :#{name} should implement method `\#{method}`"
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

  contract(Nilor[Symbol], Kwargs[each: Nilor[ReeMapper::Field], optional: Bool, key: Nilor[Symbol]], Ksplat[RestKeys => Any], Optblock => Nilor[ReeMapper::Field])
  def array(field_name = nil, each: nil, optional: false, key: nil, **opts, &blk)
    raise ReeMapper::Error, "invalid DSL usage" unless @mapper
    raise ArgumentError, "array item can't be optional" if field_name.nil? && optional
    raise ArgumentError, 'array type should use either :each or :block' if each && blk || !each && !blk
    raise ArgumentError, 'invalid :key option value' unless HASH_KEY_OPTION_VALUES.include?(key)

    if blk
      each = ReeMapper::Field.new(
        hash_from_blk(key: key, &blk)
      )
    end

    type = ReeMapper::Mapper.build(@mapper.strategies, ReeMapper::Array.new(each))

    return ReeMapper::Field.new(type, optional: optional, **opts) unless field_name

    @mapper.add_field(type, field_name, optional: optional, **opts)
  end

  contract(Symbol, Any, Ksplat[RestKeys => Any] => Nilor[ReeMapper::Field])
  def array?(field_name, each:, **opts)
    raise ArgumentError if opts.key?(:optional)

    array(field_name, each: each, optional: true, **opts)
  end

  contract(Symbol, Kwargs[key: Nilor[Symbol]], Ksplat[RestKeys => Any], Block => nil)
  def hash(field_name, key: nil, **opts, &blk)
    raise ReeMapper::Error, "invalid DSL usage" unless @mapper
    raise ArgumentError, 'invalid :key option value' unless HASH_KEY_OPTION_VALUES.include?(key)

    type = hash_from_blk(key: key, &blk)

    @mapper.add_field(type, field_name, **opts)
  end

  contract(Symbol, Ksplat[RestKeys => Any], Block => nil)
  def hash?(field_name, **opts, &blk)
    hash(field_name, optional: true, **opts, &blk)
  end

  private

  def hash_from_blk(key:, &blk)
    mapper_proxy = self.class.call

    strategies = @mapper.strategies.map do |strategy|
      strategy = strategy.dup
      output = strategy.output
      if key
        strategy.output = HASH_KEY_OPTION_MAP.fetch(key).new
      elsif !(output.is_a?(ReeMapper::SymbolKeyHashOutput) || output.is_a?(ReeMapper::StringKeyHashOutput))
        strategy.output = ReeMapper::SymbolKeyHashOutput.new
      end
      strategy
    end

    strategies[0..-2].each do |strategy|
      mapper_proxy.use(strategy)
    end

    _hsh_mapper = mapper_proxy.use(strategies.last, &blk)
  end
end
