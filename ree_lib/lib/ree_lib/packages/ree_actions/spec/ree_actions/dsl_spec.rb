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
end