package_require("ree_actions/dsl")

RSpec.describe ReeActions::DSL, type: [:autoclean] do
  link :build_sqlite_connection, from: :ree_dao

  before(:all) do
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

    connection.disconnect
  end

  before do
    Ree.enable_irb_mode
  end

  after do
    Ree.disable_irb_mode
  end

  it {
    module ReeActionsTest
      include Ree::PackageDSL

      package do
        depends_on :ree_mapper
        depends_on :ree_dao
      end

      class TestAction
        include ReeActions::DSL

        action :test_action

        ActionCaster = build_mapper.use(:cast) do
          integer :user_id
        end

        contract Any, ActionCaster.dto(:cast) => Integer
        def call(user_access, attrs)
          attrs[:user_id]
        end
      end
    end

    result = ReeActionsTest::TestAction.new.call('user_access', {user_id: 1})
    expect(result).to eq(1)
  }

  it {
    module ReeActionsTest
      include Ree::PackageDSL

      package do
        depends_on :ree_mapper
        depends_on :ree_dao
      end

      class TestAction2
        include ReeActions::DSL

        action :test_action2

        contract Any, Hash => Integer
        def call(user_access, attrs)
          attrs[:user_id]
        end
      end
    end

    result = ReeActionsTest::TestAction2.new.call('user_access', {user_id: 1})
    expect(result).to eq(1)
  }

  it {
    module ReeActionsTest
      include Ree::PackageDSL

      package do
        depends_on :ree_mapper
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

      class User
        include ReeDto::EntityDSL

        properties(
          id: Nilor[Integer],
          name: String,
          age: Integer,
        )

        attr_accessor :name
      end

      class UsersDao
        include ReeDao::DSL

        dao :users_dao do
          link :db
        end

        table :users

        schema ReeActionsTest::User do
          integer :id, null: true
          string :name
          integer :age
        end
      end

      class TestAction3
        include ReeActions::DSL

        action :test_action3 do
          link :users_dao
        end

        contract Any, Hash => Integer
        def call(user_access, attrs)
          $user = ReeActionsTest::User.new(name: 'John', age: 30)
          users_dao.put($user)

          Thread.new do
            users_dao.put(ReeActionsTest::User.new(name: 'Alex', age: 33))
          end.join

          Thread.new do
            users_dao.put(ReeActionsTest::User.new(name: 'David', age: 21))

            Thread.new do
              users_dao.put(ReeActionsTest::User.new(name: 'Sam', age: 19))
            end.join
          end.join
          
          $thread_cache = ReeDao::DaoCache.new.get(:users, $user.id)

          attrs[:user_id]
        end
      end
    end

    Thread.new do
      ReeActionsTest::TestAction3.new.call('user_access', {user_id: 1})
    end.join

    expect($thread_cache).to eq($user.to_h)
  }
end