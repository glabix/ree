# frozen_string_literal: true

package_require('ree_string/functions/underscore')

module ReeDao::DSL
  def self.included(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
    base.include(Ree::Inspectable)
  end

  def self.extended(base)
    base.extend(ClassMethods)
    base.include(InstanceMethods)
  end

  module InstanceMethods
    def build
      dataset_class = db.dataset_class
      klass = self.class.const_set(:Dao, Class.new(dataset_class))
      filters = self.class.instance_variable_get(:@filters) || []

      filters.each do |filter|
        klass.define_method(filter.name, &filter.proc)
      end

      db.dataset_class = klass

      dao = build_dao(
        connection: db,
        table_name: self.class.instance_variable_get(:@table),
        mapper: get_schema_mapper,
        primary_key: self.class.instance_variable_get(:@primary_key),
        default_select_columns: self.class.instance_variable_get(:@default_select_columns),
      )

      db.dataset_class = dataset_class

      dao
    end

    def get_schema_mapper
      mapper = self
        .class
        .instance_variable_get(:@schema_mapper)

      if mapper.nil?
        raise Ree::Error.new("Dao schema mapper is not set. Use `schema` DSL to define it", :invalid_dsl_usage)
      end

      mapper
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
      dsl.tags(["object", "dao"])

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
      mapper_factory = ReeMapper.get_mapper_factory(
        Object.const_get(self.name.split('::').first)
      )

      mapper = mapper_factory
        .call
        .use(:db_dump)
        .use(:db_load, dto: dto_class, &proc)

      self.instance_variable_set(:@schema_mapper, mapper)
      nil
    end

    DaoFilter = Struct.new(:name, :proc)

    contract Symbol, Proc => nil
    def filter(name, proc)
      filters = self.instance_variable_get(:@filters)

      if filters.nil?
        filters = []
        self.instance_variable_set(:@filters, filters)
      end

      filters.push(DaoFilter.new(name, proc))

      nil
    end
  end
end