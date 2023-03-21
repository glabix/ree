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

    klass.register_type(:bool, ReeMapper::Bool.new)
    klass.register_type(:date_time, ReeMapper::DateTime.new)
    klass.register_type(:time, ReeMapper::Time.new)
    klass.register_type(:date, ReeMapper::Date.new)
    klass.register_type(:float, ReeMapper::Float.new)
    klass.register_type(:integer, ReeMapper::Integer.new)
    klass.register_type(:string, ReeMapper::String.new)
    klass.register_type(:any, ReeMapper::Any.new)

    klass
  end
end
