# frozen_string_literal: true

package_require('ree_string/functions/underscore')

module ReeDao::DSL
  def self.included(base)
    setup_semaphore(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  def self.extended(base)
    setup_semaphore(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  def self.setup_semaphore(base)
    mod = Object.const_get(base.name.split('::').first)
    return if mod.const_defined?(:MAPPER_SEMAPHORE)

    mod.const_set(:MAPPER_SEMAPHORE, Mutex.new)
    mod.private_constant :MAPPER_SEMAPHORE
  end

  module InstanceMethods
    def build
      build_dao(
        connection: db,
        table_name: self.class.instance_variable_get(:@table),
        mapper: self.class.instance_variable_get(:@schema_mapper) || (raise Ree::Error.new("Dao schema mapper is not set. Use `schema` DSL to define it", :invalid_dsl_usage)),
        primary_key: self.class.instance_variable_get(:@primary_key),
        default_select_columns: self.class.instance_variable_get(:@default_select_columns),
      )
    end
  end

  module ClassMethods
    include Ree::Contracts::Core
    include Ree::Contracts::ArgContracts

    contract Symbol, Block => Ree::Object
    def dao(name, &proc)
      if !block_given?
        raise Ree::Error.new("dao requires block to link specific db connection as :db => link :some_db, as: :db", :invalid_dsl_usage)
      end

      dsl = Ree::ObjectDsl.new(
        Ree.container.packages_facade, name, self, :object
      )

      dsl.instance_exec(&proc)

      db_link = dsl.object.links.detect { _1.as == :db }

      if !db_link
        raise Ree::Error.new("dao should link specific db connection as :db => link :some_db, as: :db", :invalid_dsl_usage)
      end

      if dsl.object.factory? && dsl.object.factory != :build
        raise Ree::Error.new("dao DSL automatically assigns `factory :build` to object. Custom factory methods are not supported", :invalid_dsl_usage)
      end

      dsl.link(:build_dao, from: :ree_dao)
      dsl.factory(:build)
      dsl.singleton

      # automatically assign table name from object class
      table(
        ReeString::Underscore.new
          .call(self.name.split("::").last.gsub(/dao$/i, ''))
          .to_sym
      )

      Ree.container.compile(dsl.package, name)
    end

    contract Symbol => Symbol
    def table(table_name)
      @table = table_name
    end

    contract Or[Symbol, ArrayOf[Symbol]] => nil
    def primary_key(primary_key)
      @primary_key = primary_key
      nil
    end

    contract ArrayOf[Symbol] => nil
    def default_select_columns(columns)
      @default_select_columns = columns
      nil
    end

    contract(Class, Block => nil)
    def schema(dto_class, &proc)
      mapper = build_or_get_mapper_factory
        .call
        .use(:db_dump)
        .use(:db_load, dto: dto_class, &proc)

      self.instance_variable_set(:@schema_mapper, mapper)
      nil
    end

    private

    def build_or_get_mapper_factory
      mod = Object.const_get(name.split('::').first)
      factory = mod.instance_variable_get(:@mapper_factory)
      return factory if factory

      mod.const_get(:MAPPER_SEMAPHORE).synchronize do
        factory = build_mapper_factory(mod)
        mod.instance_variable_set(:@mapper_factory, factory)
      end

      factory
    end

    def build_mapper_factory(mod)
      pckg_name = ReeString::Underscore.new.call(mod.name)
      factory_path = "#{pckg_name}/mapper_factory"

      mapper_factory_klass = if package_file_exists?(factory_path) && mod != ReeMapper
        package_require(factory_path)
        Object.const_get("#{mod.name}::MapperFactory")
      else
        ReeMapper::DefaultFactory
      end

      mapper_factory_klass.new
    end
  end
end