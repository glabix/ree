module ReeMigratorTest
  include Ree::PackageDSL

  package do
    depends_on :ree_dao
  end

  class Db
    include Ree::BeanDSL

    bean :db do
      singleton
      factory :build

      link :build_sqlite_connection, from: :ree_dao
    end

    def build
      build_sqlite_connection({database: 'sqlite_db'})
    end
  end
end