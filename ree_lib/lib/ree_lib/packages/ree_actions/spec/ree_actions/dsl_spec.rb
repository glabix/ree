package_require("ree_actions/dsl")

RSpec.describe ReeActions::DSL, type: [:autoclean] do
  before :all do
    Ree.enable_irb_mode

    module ReeActionsTest
      include Ree::PackageDSL

      package
    end

    class ReeActionsTest::EmptyActions
      include ReeActions::DSL

      actions :empty_actions do
      end
    end

    class ReeActionsTest::Cmd
      include Ree::FnDSL

      fn :cmd

      def call
      end
    end

    class ReeActionsTest::Serializer
      include ReeMapper::DSL

      mapper :serializer

      build_mapper.use(:serialize) do
        integer :id
      end
    end

    class ReeActionsTest::Caster
      include ReeMapper::DSL

      mapper :caster

      build_mapper.use(:cast) do
        integer :id
      end
    end

    class ReeActionsTest::Actions
      include ReeActions::DSL

      actions :actions do
        default_warden_scope :user

        post "users" do
          summary "Test action"
          action :cmd, from: :ree_actions_test
          serializer :serializer, from: :ree_actions_test
          respond_to :json
        end

        get "files.csv" do
          summary "Test action"
          action :cmd, from: :ree_actions_test
          respond_to :csv
        end
      end
    end
  end

  after :all do
    Ree.disable_irb_mode
  end

  it {
    expect(ReeActionsTest::EmptyActions.new).to eq([])
  }

  it {
    actions = ReeActionsTest::Actions.new

    expect(actions.size).to eq(2)

    post_action = actions.first
    csv_action = actions.last

    expect(post_action.serializer.name).to eq(:serializer)
    expect(post_action.action.name).to eq(:cmd)
    expect(post_action.respond_to).to eq(:json)

    expect(csv_action.respond_to).to eq(:csv)
  }
end