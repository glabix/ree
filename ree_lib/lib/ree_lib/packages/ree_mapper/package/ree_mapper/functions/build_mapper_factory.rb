# frozen_string_literal: true

class ReeMapper::BuildMapperFactory
  include Ree::FnDSL

  fn :build_mapper_factory do
    link 'ree_mapper/mapper', -> { Mapper }
    link 'ree_mapper/mapper_factory', -> { MapperFactory }
    link 'ree_mapper/mapper_strategy', -> { MapperStrategy }
  end

  contract(ArrayOf[MapperStrategy] => SubclassOf[MapperFactory])
  def call(strategies:)
    klass = Class.new(ReeMapper::MapperFactory)

    klass.instance_eval {
      @types = {}
      @strategies = strategies
    }

    klass.register(:bool, Mapper.build(strategies, ReeMapper::Bool.new))
    klass.register(:date_time, Mapper.build(strategies, ReeMapper::DateTime.new))
    klass.register(:time, Mapper.build(strategies, ReeMapper::Time.new))
    klass.register(:date, Mapper.build(strategies, ReeMapper::Date.new))
    klass.register(:float, Mapper.build(strategies, ReeMapper::Float.new))
    klass.register(:integer, Mapper.build(strategies, ReeMapper::Integer.new))
    klass.register(:string, Mapper.build(strategies, ReeMapper::String.new))

    klass
  end
end
