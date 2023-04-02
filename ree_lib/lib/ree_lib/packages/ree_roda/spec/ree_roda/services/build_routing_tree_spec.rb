# frozen_string_literal = true

RSpec.describe :build_routing_tree do
  link :build_routing_tree, from: :ree_roda
  link :is_blank, from: :ree_object
  link :not_blank, from: :ree_object

  before :all do
    Ree.enable_irb_mode

    module ReeRodaTestTree
      include Ree::PackageDSL

      package do
        depends_on :ree_actions
        depends_on :ree_dao
      end
    end

    class ReeRodaTestTree::Cmd
      include ReeActions::DSL

      action :cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
        integer? :task_id
      end

      def call(access, attrs)
      end
    end

    class ReeRodaTestTree::TestRoutes
      include ReeRoutes::DSL

      routes :test_routes do
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

        delete "api/tasks/:task_id" do
          summary "Some action"
          action :cmd, **opts
        end

        get "api/tasks/:id/types" do
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
      plugin :ree_routes

      ree_routes ReeRodaTestTree::TestRoutes.new

      route do |r|
        r.get "health" do
          "success"
        end

        r.ree_routes
      end
    end
  end

  after :all do
    Ree.disable_irb_mode
  end

  let(:routes) { TestTreeApp.instance_variable_get(:@ree_routes) }

  let(:hsh_tree) {
    {
      value: "api",
      depth: 0,
      parent: nil,
      type: :string,
      children: [
        {
          value: "actions",
          depth: 1,
          parent: "api",
          type: :string,
          children: [
            {
              value: ":id",
              depth: 2,
              parent: "actions",
              type: :param,
              children: [
                {
                  value: "types",
                  depth: 3,
                  parent: ":id",
                  type: :string,
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
          type: :string,
          children: [
            {
              value: ":id",
              depth: 2,
              parent: "tasks",
              type: :param,
              children: [
                {
                  value: "types",
                  depth: 3,
                  parent: ":id",
                  type: :string,
                  children: []
                }
              ]
            }
          ]
        },
        {
          value: "users",
          depth: 1,
          parent: "api",
          type: :string,
          children: [
            {
              value: "collection",
              depth: 2,
              parent: "users",
              type: :string,
              children: [
                {
                  value: ":id",
                  depth: 3,
                  parent: "collection",
                  type: :param,
                  children: [
                    {
                      value: "info",
                      depth: 4,
                      parent: ":id",
                      type: :string,
                      children: []
                    }
                  ]
                }
              ]
            },
            {
              value: ":id",
              depth: 2,
              parent: "users",
              type: :param,
              children: []
            }
          ]
        },
        {
          value: "accounts",
          depth: 1,
          parent: "api",
          type: :string,
          children: []
        }
      ]
    }
  }

  it {
    tree = build_routing_tree(routes)

    # check that all end nodes have routes
    # and that not end nodes don't have route
    id_nodes = [*tree.find_by_value(value: ":id", depth: 2), *tree.find_by_value(value: ":id", depth: 4)]
    types_node = tree.find_by_value(value: "types", depth: 3)
    actions_node = tree.find_by_value(value: "actions", depth: 1)
    tasks_node = tree.find_by_value(value: "tasks", depth: 1)

    def count_tree_routes(tree, count = 0)
      count += tree.routes.count
      if tree.children.length > 0
        return tree.children.map do |children|
          count_tree_routes(children, count)
        end.sum
      end
      return count
    end

    expect(is_blank(tree.routes)).to eq(true)
    expect(not_blank(actions_node.routes)).to eq(true)
    expect(not_blank(tasks_node.routes)).to eq(true)
    expect(id_nodes.all? { not_blank(_1.routes) }).to eq(true)
    expect(count_tree_routes(tree)).to eq(13)

    # hsh = to_hash(tree)
    # expect(except(hsh, global_except: [:routes])).to eq(hsh_tree)
  }
end