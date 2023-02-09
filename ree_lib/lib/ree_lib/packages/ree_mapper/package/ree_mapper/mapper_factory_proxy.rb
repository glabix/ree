# frozen_string_literal: true

class ReeMapper::MapperFactoryProxy
  attr_reader :mapper_factory, :register_as, :strategies, :after_build

  contract(
    Class, # SubclassOf[ReeMapper::MapperFactory],
    Kwargs[
      register_as: Nilor[Symbol]
    ],
    Optblock => Any
  )
  def initialize(mapper_factory, register_as:, &blk)
    @mapper_factory = mapper_factory
    @register_as    = register_as
    @strategies     = []
    @after_build    = blk
  end

  contract(Or[Symbol, ReeMapper::MapperStrategy], Kwargs[dto: Nilor[Class]], Optblock => Or[ReeMapper::MapperFactoryProxy, ReeMapper::Mapper]).throws(ArgumentError)
  def use(strategy_or_method, dto: nil, &blk)
    if strategy_or_method.is_a?(ReeMapper::MapperStrategy)
      strategy = strategy_or_method
    else
      strategy = mapper_factory.strategies.detect { _1.method == strategy_or_method }
      raise ArgumentError, "MapperFactory strategy :#{strategy_or_method} not found" unless strategy
      strategy = strategy.dup
      strategy.dto = dto if dto
    end

    self.strategies << strategy

    return self unless blk

    mapper = ReeMapper::Mapper.build(strategies)
    mapper_factory.new(mapper).instance_exec(&blk)
    mapper.prepare_dto

    mapper_factory.register(register_as, mapper) if register_as

    after_build&.call(mapper)

    mapper
  end
end
