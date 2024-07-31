# frozen_string_literal: true

class ReeMapper::BuildMapperFactory
  include Ree::FnDSL

  fn :build_mapper_factory do
    with_caller
    link 'ree_mapper/mapper', -> { Mapper }
    link 'ree_mapper/mapper_factory', -> { MapperFactory }
    link 'ree_mapper/mapper_strategy', -> { MapperStrategy }
  end

  SEMAPHORE = Mutex.new

  contract(ArrayOf[MapperStrategy] => SubclassOf[MapperFactory])
  def call(strategies:)
    mod = if get_caller.is_a?(Module)
      get_caller
    else
      name = get_caller.class.to_s.split("::").first
      Object.const_get(name)
    end

    klass = nil

    SEMAPHORE.synchronize do
      if klass = mod.instance_variable_get(:@mapper_factory)
        klass.instance_eval do
          @strategies = strategies
        end
      else
        klass = Class.new(ReeMapper::MapperFactory)

        klass.instance_eval do
          @types = {}
          @wrappers = {}
          @strategies = strategies
        end

        mod.instance_variable_set(:@mapper_factory, klass)
      end

      register_default_types(klass)
    end

    klass
  end

  private

  def register_default_types(klass)
    types = klass.instance_variable_get(:@types)
    strategies = klass.instance_variable_get(:@strategies)

    return if !types.empty?
    return if strategies.empty?

    klass.register_type(:bool, ReeMapper::Bool.new)
    klass.register_type(:date_time, ReeMapper::DateTime.new)
    klass.register_type(:time, ReeMapper::Time.new)
    klass.register_type(:date, ReeMapper::Date.new)
    klass.register_type(:float, ReeMapper::Float.new)
    klass.register_type(:integer, ReeMapper::Integer.new)
    klass.register_type(:string, ReeMapper::String.new)
    klass.register_type(:any, ReeMapper::Any.new)
    klass.register_type(:rational, ReeMapper::Rational.new)

    klass.register_wrapper(:array, ReeMapper::Array)
  end
end
