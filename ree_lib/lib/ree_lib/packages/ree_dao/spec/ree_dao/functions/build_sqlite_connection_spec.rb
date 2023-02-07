# frozen_string_literal = true

package_require('ree_dao')
package_require('ree_dto/entity_dsl')

RSpec.describe :build_sqlite_connection do
  link :build_sqlite_connection, from: :ree_dao

  after do
    Ree.disable_irb_mode
  end

  before :all do
    connection = build_sqlite_connection({database: 'sqlite_db'})

    if connection.table_exists?(:users)
      connection.drop_table(:users)
    end

    if connection.table_exists?(:products)
      connection.drop_table(:products)
    end

    connection.create_table :users do
      primary_key :id

      column  :name, 'varchar(256)'
      column  :age, :integer
    end

    connection.create_table :products do
      primary_key :id

      column  :title, 'varchar(256)'
    end

    connection.disconnect
  end

  Ree.enable_irb_mode

  module ReeDaoTest
    include Ree::PackageDSL

    package do
      depends_on :ree_dao
    end
  end

  class ReeDaoTest::Db
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

  class ReeDaoTest::User
    include ReeDto::EntityDSL

    properties(
      id: Nilor[Integer],
      name: String,
      age: Integer,
    )

    attr_accessor :name
  end

  class ReeDaoTest::Product
    include ReeDto::EntityDSL

    properties(
      id: Nilor[Integer],
      title: String,
    )

    attr_accessor :title
  end

  class ReeDaoTest::UsersDao
    include ReeDao::DSL

    dao :users_dao do
      link :db
    end

    table :users

    schema ReeDaoTest::User do
      integer :id, null: true
      string :name
      integer :age
    end

    filter :by_name, -> (name) { where(name: name) }
  end

  class ReeDaoTest::ProductsDao
    include ReeDao::DSL

    dao :products_dao do
      link :db
    end

    schema ReeDaoTest::Product do
      integer :id, null: true
      string :title
    end
  end

  let(:dao) { ReeDaoTest::UsersDao.new }
  let(:products_dao) { ReeDaoTest::ProductsDao.new }

  it {
    user = ReeDaoTest::User.new(name: 'John', age: 30)
    dao.put(user)

    u = dao.find(user.id)

    expect(user.id).to be_a(Integer)
    expect(user.name).to eq(u.name)
    expect(user.age).to eq(u.age)
  }

  it {
    dao.delete_all

    user = ReeDaoTest::User.new(name: 'John', age: 30)
    dao.put(user)

    u = dao.find(user.id)

    expect(u).to be_a(ReeDaoTest::User)

    state = u.instance_variable_get(:@persistence_state)

    expect(state).to be_a(Hash)
    expect(state[:id]).to eq(user.id)
    expect(state[:age]).to eq(user.age)
    expect(state[:name]).to eq(user.name)
  }

  it {
    dao.delete_all

    user = ReeDaoTest::User.new(name: 'John', age: 30)
    dao.put(user)

    u = dao.find(user.id, :read)
    expect(u).to be_a(ReeDaoTest::User)
    expect(u.instance_variable_get(:@persistence_state)).to eq(nil)

    all = dao.all
    expect(all.size).to eq(1)
    u = all.first

    expect(u).to be_a(ReeDaoTest::User)
    expect(u.instance_variable_get(:@persistence_state)).to be_a(Hash)
  }

  it {
    dao.delete_all

    user = ReeDaoTest::User.new(name: 'John', age: 30)
    dao.put(user)

    user.name = 'Doe'
    dao.update(user)

    user = dao.find(user.id)
    expect(user.name).to eq('Doe')
  }

  it {
    dao.delete_all
    products_dao.delete_all

    user = ReeDaoTest::User.new(name: 'John', age: 30)
    dao.put(user)

    product = ReeDaoTest::Product.new(title: 'Product')
    products_dao.put(product)

    user = dao.find(user.id)
    product = products_dao.find(product.id)
    expect(user.name).to eq('John')
    expect(product.title).to eq('Product')
  }

  context "scoped filters" do
    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      dao.put(user)

      user = ReeDaoTest::User.new(name: 'Peter', age: 32)
      dao.put(user)

      expect(dao.by_name('John').count).to eq(1)
      expect(dao.by_name('Peter').count).to eq(1)
      expect(dao.count).to eq(2)
    }

    it {
      expect {
        products_dao.by_name('test')
      }.to raise_error(NoMethodError)
    }
  end

  context "#count" do
    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      dao.put(user)

      expect(dao.count).to eq(1)
    }
  end

  context "update by condition" do
    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      other_user = ReeDaoTest::User.new(name: 'Steve', age: 30)
      dao.put(user)
      dao.put(other_user)

      dao.where(name: 'John').update(name: 'Doe')

      user = dao.find(user.id)
      other_user = dao.find(other_user.id)
      expect(user.name).to eq('Doe')
      expect(other_user.name).to eq('Steve')
    }
  end

  context "uodate by entity" do
    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      dao.put(user)

      user.name = 'Doe'

      dao.where(name: 'John').update(user)

      user = dao.find(user.id)
      expect(user.name).to eq('Doe')
    }
  end

  context "delete by condition" do
    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      other_user = ReeDaoTest::User.new(name: 'Steve', age: 30)

      dao.put(user)
      dao.put(other_user)

      dao.where(name: 'John').delete(name: 'John')

      user = dao.find(user.id)
      other_user = dao.find(other_user.id)

      expect(user).to eq(nil)
      expect(other_user.id).to be_a(Integer)
    }
  end

  context "delete by entity" do
    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      dao.put(user)

      user.name = 'Doe'

      dao.where(name: 'John').delete(user)

      user = dao.find(user.id)
      expect(user).to eq(nil)
    }

    it {
      dao.delete_all

      user = ReeDaoTest::User.new(name: 'John', age: 30)
      dao.put(user)

      user.name = 'Doe'

      dao.delete(user)

      user = dao.find(user.id)
      expect(user).to eq(nil)
    }
  end
end
