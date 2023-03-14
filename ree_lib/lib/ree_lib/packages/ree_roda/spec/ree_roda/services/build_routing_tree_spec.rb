# frozen_string_literal = true

RSpec.describe :build_routing_tree do
  link :build_routing_tree, from: :ree_roda
  link :except, from: :ree_hash
  link :to_hash, from: :ree_object

  before :all do
    Ree.enable_irb_mode

    module ReeRodaTest
      include Ree::PackageDSL

      package
    end

    class ReeRodaTest::Cmd
      include ReeActions::ActionDSL

      action :cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
      end

      def call(access, attrs)
      end
    end

    class ReeRodaTest::TestActions
      include ReeActions::DSL

      actions :test_actions do
        default_warden_scope :identity
        opts = {from: :ree_roda_test}

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
      end
    end

    class TestApp < ReeRoda::App
      plugin :ree_actions

      ree_actions ReeRodaTest::TestActions.new

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

  let(:actions) { TestApp.instance_variable_get(:@ree_actions) }

  let(:hsh_tree) {
    {
      value: 'api',
      depth: 0,
      children: [
        {
          value: 'actions',
          depth: 1,
          children: [
            {
              value: ':id',
              depth: 2,
              children: [
                {
                  value: 'types',
                  depth: 3,
                  children: []
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
    expect(tree.find_by_value(value: ':id', depth: 2).actions.count).to eq(2)
    expect(
      tree.find_by_value(value: ':id', depth: 2).actions.map(&:request_method).sort
    ).to eq([:delete, :get])

    hsh = to_hash(tree)
    expect(except(hsh, global_except: [:actions])).to eq(hsh_tree)
  }
end