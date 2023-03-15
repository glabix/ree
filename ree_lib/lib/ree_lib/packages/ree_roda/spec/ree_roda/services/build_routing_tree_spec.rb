# frozen_string_literal = true

RSpec.describe :build_routing_tree do
  link :build_routing_tree, from: :ree_roda
  link :except, from: :ree_hash
  link :is_blank, from: :ree_object
  link :not_blank, from: :ree_object
  link :to_hash, from: :ree_object

  before :all do
    Ree.enable_irb_mode

    module ReeRodaTestTree
      include Ree::PackageDSL

      package
    end

    class ReeRodaTestTree::Cmd
      include ReeActions::ActionDSL

      action :cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
      end

      def call(access, attrs)
      end
    end

    class ReeRodaTestTree::TestActions
      include ReeActions::DSL

      actions :test_actions do
        default_warden_scope :identity
        opts = { from: :ree_roda_test_tree }

        get "api/actions/:id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
        end

        post "api/actions" do
          summary "Some action"
          action :cmd, **opts
        end

        delete "api/actions/:id" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/actions/:id/types" do
          summary "Some action"
          action :cmd, **opts
        end

        post "api/actions/:id/types" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/tasks" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/tasks/:id" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/users/:id" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/users/collection/:id" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/users/collection/:id/info" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/accounts" do
          summary "Some action"
          action :cmd, **opts
        end
      end
    end

    class TestTreeApp < ReeRoda::App
      plugin :ree_actions

      ree_actions ReeRodaTestTree::TestActions.new

      route do |r|
        r.get "health" do
          "success"
        end

        r.ree_actions
      end
    end
  end

  after :all do
    Ree.disable_irb_mode
  end

  let(:actions) { TestTreeApp.instance_variable_get(:@ree_actions) }

  let(:hsh_tree) {
    {
      value: "api",
      depth: 0,
      parent: nil,
      children: [
        {
          value: "actions",
          depth: 1,
          parent: "api",
          children: [
            {
              value: ":id",
              depth: 2,
              parent: "actions",
              children: [
                {
                  value: "types",
                  depth: 3,
                  parent: ":id",
                  children: []
                }
              ]
            }
          ]
        },
        {
          value: "tasks",
          depth: 1,
          parent: "api",
          children: [
            {
              value: ":id",
              depth: 2,
              parent: "tasks",
              children: []
            }
          ]
        },
        {
          value: "users",
          depth: 1,
          parent: "api",
          children: [
            {
              value: "collection",
              depth: 2,
              parent: "users",
              children: [
                {
                  value: ":id",
                  depth: 3,
                  parent: "collection",
                  children: [
                    {
                      value: "info",
                      depth: 4,
                      parent: ":id",
                      children: []
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  }

  it {
    tree = build_routing_tree(actions)

    # check that all end nodes have actions
    # and that not end nodes don't have actions
    id_nodes = tree.find_by_value(value: ":id", depth: 2)
    types_node = tree.find_by_value(value: "types", depth: 3)
    actions_node = tree.find_by_value(value: "actions", depth: 1)
    tasks_node = tree.find_by_value(value: "tasks", depth: 1)


    expect(is_blank(tree.actions)).to eq(true)
    expect(not_blank(actions_node.actions)).to eq(true)
    expect(not_blank(tasks_node.actions)).to eq(true)
    expect(id_nodes.all? { not_blank(_1.actions) }).to eq(true)
    expect(not_blank(types_node.actions)).to eq(true)
    expect(types_node.actions.count).to eq(2)

    hsh = to_hash(tree)
    expect(except(hsh, global_except: [:actions])).to eq(hsh_tree)
  }  
end