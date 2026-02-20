# frozen_string_literal: true

class ReeMapper::BuildMapperStrategy
  include Ree::FnDSL

  fn :build_mapper_strategy

  contract(
    Kwargs[
      method: Symbol,
      dto: Class,
      always_optional: Bool
    ] => ReeMapper::MapperStrategy
  )
  def call(method:, dto: Hash, always_optional: false)
    ReeMapper::MapperStrategy.new(
      method: method,
      dto: dto,
      always_optional: always_optional
    )
  end
end
