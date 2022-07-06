# frozen_string_literal = true

package_require('ree_dao')
package_require('ree_dto/entity')

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

    connection.create_table :users do
      primary_key :id
  
      column  :name, 'varchar(256)'
      column  :age, :integer
    end

    connection.disconnect
  end

  Ree.enable_irb_mode  

  class ReeDao::Db
    include Ree::BeanDSL

    bean :db do
      singleton
      factory :build

      link :build_sqlite_connection
    end

    def build
      build_sqlite_connection({database: 'sqlite_db'})
    end
  end

  class ReeDao::User < ReeDto::Entity
    properties(
      id: Nilor[Integer],
      name: String,
      age: Integer,
    )

    attr_accessor :name
  end

  class ReeDao::UsersDao
    include ReeDao::DSL

    dao :users_dao do
      link :db
    end

    table :users

    schema ReeDao::User do
      integer :id, null: true
      string :name
      integer :age
    end
  end

  let(:dao) { ReeDao::UsersDao.new }

  it {
    user = ReeDao::User.new(name: 'John', age: 30)
    dao.put(user)

    u = dao.find(user.id)

    expect(user.id).to be_a(Integer)
    expect(user.name).to eq(u.name)
    expect(user.age).to eq(u.age)
  }

  it {
    dao.delete_all

    user = ReeDao::User.new(name: 'John', age: 30)
    dao.put(user)

    u = dao.find(user.id)

    expect(u).to be_a(ReeDao::User)

    state = u.instance_variable_get(:@persistence_state)

    expect(state).to be_a(Hash)
    expect(state[:id]).to eq(user.id)
    expect(state[:age]).to eq(user.age)
    expect(state[:name]).to eq(user.name)
  }

  it {
    dao.delete_all

    user = ReeDao::User.new(name: 'John', age: 30)
    dao.put(user)

    u = dao.find(user.id, :read)
    expect(u).to be_a(ReeDao::User)
    expect(u.instance_variable_get(:@persistence_state)).to eq(nil)

    all = dao.all
    expect(all.size).to eq(1)
    u = all.first

    expect(u).to be_a(ReeDao::User)
    expect(u.instance_variable_get(:@persistence_state)).to be_a(Hash)
  }

  it {
    dao.delete_all
    
    user = ReeDao::User.new(name: 'John', age: 30)
    dao.put(user)

    user.name = 'Doe'
    dao.update(user)

    user = dao.find(user.id)
    expect(user.name).to eq('Doe')
  }
end
