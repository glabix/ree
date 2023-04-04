# frozen_string_literal: true

package_require("ree_dao/wrappers/pg_jsonb")
package_require("ree_dao/wrappers/pg_array")

RSpec.describe :build_pg_connection do
  link :build_pg_connection, from: :ree_dao

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_pg_connection({adapter: 'postgres'}, **{extensions: [:pg_array, :pg_json]})

    if connection.table_exists?(:products)
      connection.drop_table(:products)
    end

    connection.create_table :products do
      primary_key :id

      column  :title, 'varchar(256)'
      column  :info, :jsonb
      column  :labels, :"varchar(30)[]"
    end

    connection.disconnect
  end

  Ree.enable_irb_mode

  module ReeDaoTest
    include Ree::PackageDSL

    package do
      depends_on :ree_dao
      depends_on :ree_mapper
    end

    class MapperFactory
      include Ree::BeanDSL

      bean :mapper_factory do
        factory :build
        singleton

        link :build_mapper_factory, from: :ree_mapper
        link :build_mapper_strategy, from: :ree_mapper
      end

      def build
        factory = build_mapper_factory(strategies: [
          build_mapper_strategy(method: :cast, dto: Hash),
          build_mapper_strategy(method: :serialize, dto: Hash),
          build_mapper_strategy(method: :db_dump, dto: Hash),
          build_mapper_strategy(method: :db_load, dto: Object, always_optional: true)
        ])

        factory
          .register_wrapper(:pg_jsonb, ReeDao::PgJsonb)
          .register_wrapper(:pg_array, ReeDao::PgArray)

        factory
      end
    end
  end

  require "sequel/extensions/pg_json_ops"
  require "sequel/extensions/pg_array_ops"

  class ReeDaoTest::Db
    include Ree::BeanDSL

    bean :db do
      singleton
      factory :build

      link :build_pg_connection, from: :ree_dao
    end

    def build
      Sequel.extension :pg_json_ops
      Sequel.extension :pg_array_ops

      build_pg_connection({adapter: 'postgres'}, **{extensions: [:pg_array, :pg_json]})
    end
  end

  class ReeDaoTest::Product
    include ReeDto::EntityDSL

    properties(
      id: Nilor[Integer],
      title: String,
      info: Hash,
      labels: ArrayOf[String]
    )

    attr_accessor :title, :info
  end

  class ReeDaoTest::ProductsDao
    include ReeDao::DSL

    dao :products_dao do
      link :db
    end

    schema ReeDaoTest::Product do
      integer :id, null: true
      string :title
      pg_jsonb :info, any
      pg_array :labels, string
    end
  end

  let(:products_dao) { ReeDaoTest::ProductsDao.new }

  it {
    products_dao.delete_all

    product = ReeDaoTest::Product.new(title: "Product", info: { price: 1337, count: 200 }, labels: ["Sale"])
    products_dao.put(product)

    product.info[:price] = 1440
    product.labels << "New"

    products_dao.update(product)

    product = products_dao.find(product.id)
    expect(product.title).to eq("Product")
    expect(product.info[:price]).to eq(1440)
    expect(product.labels).to eq(["Sale", "New"])
  }
end