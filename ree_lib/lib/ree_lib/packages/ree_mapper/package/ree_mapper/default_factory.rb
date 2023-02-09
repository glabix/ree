class ReeMapper::DefaultFactory
  include Ree::BeanDSL

  bean :default_factory do
    link :build_mapper_factory
    link :build_mapper_strategy

    factory :build
  end

  def build
    build_mapper_factory(strategies: [
      build_mapper_strategy(method: :cast),
      build_mapper_strategy(method: :serialize),
      build_mapper_strategy(method: :db_dump),
      build_mapper_strategy(method: :db_load, dto: Object, always_optional: true)
    ])
  end
end
