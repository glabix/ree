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

    expect {
      ReeActionsTest::TestAction.new.call('user_access', {user_id: 'not integer'})
    }.to raise_error(ReeActions::ParamError)
  }

   it {
    module ReeActionsTest
      include Ree::PackageDSL

      package do
        depends_on :ree_mapper
        depends_on :ree_dao
      end

      class TestActionWithSplatOpts
        include ReeActions::DSL

        action :test_action_with_splat_opts

        ActionCaster = build_mapper.use(:cast) do
          integer :user_id
        end

        contract Any, ActionCaster.dto(:cast), Ksplat[password?: String], Optblock => Integer
        def call(user_access, attrs, **opts, &proc)
          proc.call(opts)
          attrs[:user_id]
        end
      end
    end

    action = ReeActionsTest::TestActionWithSplatOpts.new

    result = action.call('user_access', {user_id: 1}, password: "pass") do |opts|
      expect(opts[:password]).to eq("pass")
    end

    expect(result).to eq(1)

    expect {
      ReeActionsTest::TestAction.new.call('user_access', {user_id: 'not integer'})
    }.to raise_error(ReeActions::ParamError)
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
end