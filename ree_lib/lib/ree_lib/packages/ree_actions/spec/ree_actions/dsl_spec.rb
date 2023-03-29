package_require("ree_actions/dsl")

RSpec.describe ReeActions::DSL, type: [:autoclean] do
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
          user = ReeActionsTest::User.new(name: 'John', age: 30)
          users_dao.put(user)

          thr = Thread.new {
            user2 = ReeActionsTest::User.new(name: 'Alex', age: 33)
            users_dao.put(user2)
          }

          thr.join
          
          $thread_group_cache = ReeDao::DaoCache.new.instance_variable_get(:@thread_groups)
                                                   .dig(Thread.current.group.object_id, :users)

          attrs[:user_id]
        end
      end
    end

    ReeActionsTest::TestAction3.new.call('user_access', {user_id: 1})
    expect($thread_group_cache.keys.count).to_not eq(0)
    expect($thread_group_cache.keys.count).to eq(2)
  }
end