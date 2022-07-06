class ReeMapper::DefaultFactory
  include Ree::BeanDSL

  bean :default_factory do
    link :build_mapper_factory
    link :build_mapper_strategy

    factory :build
  end

  def build
    build_mapper_factory(strategies: [
      build_mapper_strategy(method: :cast, output: :symbol_key_hash),
      build_mapper_strategy(method: :serialize, output: :symbol_key_hash),
      build_mapper_strategy(method: :db_dump, output: :symbol_key_hash),
      build_mapper_strategy(method: :db_load, output: :object, always_optional: true)
    ])
  end
end
