# frozen_string_literal: true

package_require('ree_dao')
package_require('ree_dto/entity_dsl')
package_require('ree_dto/dsl')

RSpec.describe "db_load performance mode (dao integration)" do
  link :build_sqlite_connection, from: :ree_dao

  after do
    Ree.disable_irb_mode
    Ree.disable_db_load_performance_mode
  end

  before :all do
    connection = build_sqlite_connection({database: 'sqlite_db'})

    if connection.table_exists?(:perf_mode_users)
      connection.drop_table(:perf_mode_users)
    end

    connection.create_table :perf_mode_users do
      primary_key :id

      column :name, 'varchar(256)'
      column :age, :integer
    end

    connection.disconnect
  end

  Ree.enable_irb_mode

  module ReeDaoPerfModeTest
    include Ree::PackageDSL

    package do
      depends_on :ree_dao
    end
  end

  class ReeDaoPerfModeTest::Db
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

  class ReeDaoPerfModeTest::User
    include ReeDto::EntityDSL

    properties(
      id: Nilor[Integer],
      name: String,
      age: Integer,
    )

    attr_accessor :name
  end

  class ReeDaoPerfModeTest::UserDto
    include ReeDto::DSL

    build_dto do
      field :id, Nilor[Integer]
      field :name, String
      field :age, Integer
    end
  end

  # mappers are built at class definition time, so the flag state around each
  # class body decides which db_load implementation the dao gets
  Ree.enable_db_load_performance_mode

  class ReeDaoPerfModeTest::CompiledUsersDao
    include ReeDao::DSL

    dao :compiled_users_dao do
      link :db
    end

    table :perf_mode_users

    schema ReeDaoPerfModeTest::User do
      integer :id, null: true
      string :name
      integer :age
    end
  end

  class ReeDaoPerfModeTest::CompiledDtoDao
    include ReeDao::DSL

    dao :compiled_dto_dao do
      link :db
    end

    table :perf_mode_users

    schema ReeDaoPerfModeTest::UserDto do
      integer :id, null: true
      string :name
      integer :age
    end
  end

  Ree.disable_db_load_performance_mode

  class ReeDaoPerfModeTest::GenericUsersDao
    include ReeDao::DSL

    dao :generic_users_dao do
      link :db
    end

    table :perf_mode_users

    schema ReeDaoPerfModeTest::User do
      integer :id, null: true
      string :name
      integer :age
    end
  end

  let(:compiled_dao) { ReeDaoPerfModeTest::CompiledUsersDao.new }
  let(:compiled_dto_dao) { ReeDaoPerfModeTest::CompiledDtoDao.new }
  let(:generic_dao) { ReeDaoPerfModeTest::GenericUsersDao.new }

  it "compiles the schema mapper of daos defined with the mode on" do
    compiled_mapper = ReeDaoPerfModeTest::CompiledUsersDao.instance_variable_get(:@schema_mapper)
    generic_mapper = ReeDaoPerfModeTest::GenericUsersDao.instance_variable_get(:@schema_mapper)

    expect(compiled_mapper.class.method_defined?(:__generic_db_load, false)).to be true
    expect(generic_mapper.class.method_defined?(:__generic_db_load, false)).to be false
  end

  it "reads identical entities through compiled and generic daos" do
    generic_dao.delete_all

    user = ReeDaoPerfModeTest::User.new(name: 'John', age: 30)
    generic_dao.put(user)

    from_generic = generic_dao.find(user.id)
    from_compiled = compiled_dao.find(user.id)

    expect(from_compiled.id).to eq(from_generic.id)
    expect(from_compiled.name).to eq(from_generic.name)
    expect(from_compiled.age).to eq(from_generic.age)

    expect(compiled_dao.all.map(&:id)).to eq(generic_dao.all.map(&:id))
  end

  it "keeps the update round-trip working for entity_dsl entities" do
    generic_dao.delete_all

    user = ReeDaoPerfModeTest::User.new(name: 'John', age: 30)
    compiled_dao.put(user)

    loaded = compiled_dao.find(user.id)
    loaded.name = 'Doe'
    compiled_dao.update(loaded)

    expect(generic_dao.find(user.id).name).to eq('Doe')
  end

  it "loads and updates ree_dto entities through the compiled dao" do
    compiled_dto_dao.delete_all

    dto = ReeDaoPerfModeTest::UserDto.build(id: nil, name: 'Jane', age: 25)
    compiled_dto_dao.put(dto)

    loaded = compiled_dto_dao.find(dto.id)
    expect(loaded).to be_a(ReeDaoPerfModeTest::UserDto)
    expect(loaded.name).to eq('Jane')

    loaded.name = 'Janet'
    expect(loaded.changed_fields).to eq([:name])
    compiled_dto_dao.update(loaded)

    expect(compiled_dto_dao.find(dto.id).name).to eq('Janet')
  end
end
