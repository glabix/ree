# frozen_string_literal: true

module ReeMapper
  include Ree::PackageDSL

  package do
    depends_on :ree_string
    depends_on :ree_datetime
  end

  package_require('ree_string/functions/underscore')
  package_require('ree_datetime/functions/in_default_time_zone')

  require_relative 'ree_mapper/types/abstract_type'
  require_relative 'ree_mapper/errors/error'
  require_relative 'ree_mapper/errors/coercion_error'
  require_relative 'ree_mapper/errors/type_error'
  require_relative 'ree_mapper/errors/unsupported_type_error'
  require_relative 'ree_mapper/errors/argument_error'

  require_relative 'ree_mapper/filter_fields_contract'
  require_relative 'ree_mapper/fields_filter'
  require_relative 'ree_mapper/field'

  require_relative 'ree_mapper/types/bool'
  require_relative 'ree_mapper/types/any'
  require_relative 'ree_mapper/types/date_time'
  require_relative 'ree_mapper/types/time'
  require_relative 'ree_mapper/types/date'
  require_relative 'ree_mapper/types/float'
  require_relative 'ree_mapper/types/integer'
  require_relative 'ree_mapper/types/string'
  require_relative 'ree_mapper/types/array'

  require_relative 'ree_mapper/strategy_outputs/strategy_output'
  require_relative 'ree_mapper/strategy_outputs/object_output'
  require_relative 'ree_mapper/strategy_outputs/hash_output'
  require_relative 'ree_mapper/strategy_outputs/struct_output'

  require_relative 'ree_mapper/mapper_strategy'
  require_relative 'ree_mapper/mapper'
  require_relative 'ree_mapper/mapper_factory_proxy'
  require_relative 'ree_mapper/mapper_factory'

  require_relative 'ree_mapper/default_factory'
  require_relative 'ree_mapper/dsl'

  def self.get_mapper_factory(mod)
    if !mod.is_a?(Module)
      raise Ree::Error.new("module should be provided", :invalid_dsl_usage)
    end

    if mod.name.nil?
      raise Ree::Error.new("anonymous modules are not supported", :invalid_dsl_usage)
    end

    if mod.name.split('::').size > 1
      raise Ree::Error.new("top level module should be provided", :invalid_dsl_usage)
    end

    factory = mod.instance_variable_get(:@mapper_factory)
    return factory if factory

    if !mod.instance_variable_get(:@mapper_semaphore)
      mod.instance_variable_set(:@mapper_semaphore, Mutex.new)
    end

    mod.instance_variable_get(:@mapper_semaphore).synchronize do
      factory = self.build_mapper_factory(mod)
      mod.instance_variable_set(:@mapper_factory, factory)
    end

    factory
  end

  private

  def self.build_mapper_factory(mod)
    pckg_name = ReeString::Underscore.new.call(mod.name)
    factory_path = "#{pckg_name}/mapper_factory"

    mapper_factory_klass = if package_file_exists?(factory_path) && mod != self
      package_require(factory_path)
      Object.const_get("#{mod.name}::MapperFactory")
    else
      ReeMapper::DefaultFactory
    end

    mapper_factory_klass.new
  end
end

=begin

Example of mapper declaration:

  class Products::UserCaster
    include Mapper::DSL

    mapper :user_caster

    build_mapper(register_as: :user).use(:cast) do
      integer :id
      string  :name
    end
  end

  class Products::ProductCaster
    include Mapper::DSL

    mapper :product_caster do
      link :user_caster
    end

    build_mapper.use(:cast) do
      integer :id
      string  :title
      user    :creator
    end
  end


Example of mapper usage:

  class Products::ProductQuery
    include Ree::BeanDSL

    bean :product_query do
      link :product_caster
    end

    def call
      product_caster.cast({
        id: 1,
        title: 'Product',
        creator: { id: 1, name: 'John' }
      })
    end
  end


If you need to register other packages mappers define your custom mapper factory.
Create `mapper_factory.rb` file to declare `MapperFactory` class.

  class Products::MapperFactory
    include Ree::BeanDSL

    bean :mapper_factory do
      link :build_mapper_factory
      link :build_mapper_strategy
      link :user_caster, from: :cart

      factory :build
    end

    def build
      mapper_factory = build_mapper_factory(strategies: [
        build_mapper_strategy(method: :cast,      dto: Hash),
        build_mapper_strategy(method: :serialize, dto: Hash),
        build_mapper_strategy(method: :db_dump,   dto: Hash),
        build_mapper_strategy(method: :db_load,   dto: Object)
      ])

      mapper_factory.register_mapper(:cart_user, user_caster)

      mapper_factory
    end
  end

=end
