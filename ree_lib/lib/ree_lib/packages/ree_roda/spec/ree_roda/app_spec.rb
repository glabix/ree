require "rack/test"

package_require("ree_roda/app")
package_require("ree_actions/dsl")
package_require("ree_routes/dsl")
package_require("ree_roda/plugins/ree_routes")

require "warden"

RSpec.describe ReeRoda::App do
  include Rack::Test::Methods

  before :all do
    Ree.enable_irb_mode

    module ReeRodaTest
      include Ree::PackageDSL

      package do
        depends_on :ree_actions
        depends_on :ree_dao
      end
    end

    class ReeRodaTest::Cmd
      include ReeActions::DSL

      action :cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
      end

      def call(access, attrs)
        {result: "result"}
      end
    end

    class ReeRodaTest::SerializerErrorCmd
      include ReeActions::DSL

      action :serializer_error_cmd

      def call(access, attrs)
        {result: :not_string}
      end
    end

    class ReeRodaTest::AnotherCmd
      include ReeActions::DSL

      action :another_cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
      end

      def call(access, attrs)
        {result: "another_result"}
      end
    end

    class ReeRodaTest::SubCmd
      include ReeActions::DSL

      action :sub_cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
        integer :sub_id
      end

      def call(access, attrs)
        {result: "another_result"}
      end
    end

    class ReeRodaTest::WardenScopeCmd
      include ReeActions::DSL

      action :warden_scope_cmd

      ActionCaster = build_mapper.use(:cast) do
        string? :user
        string? :another_user
      end

      def call(access, attrs)
        {result: access.to_s}
      end
    end

    class ReeRodaTest::ActionCmd
      include ReeActions::DSL

      action :action_cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :action_id
      end

      def call(access, attrs)
        {result: "action_cmd"}
      end
    end

    class ReeRodaTest::Serializer
      include ReeMapper::DSL

      mapper :serializer

      build_mapper.use(:serialize) do
        string :result
      end

      def call(access, attrs)
        {result: "result"}
      end
    end

    class ReeRodaTest::TestRoutes
      include ReeRoutes::DSL

      routes :test_routes do
        default_warden_scope :identity
        opts = {from: :ree_roda_test}

        get "some_other_route" do
          summary "Another route"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          override do |r|
            r.json do
              r.response.status = 200
              "hello"
            end
          end
        end

        get "api/action/:id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
        end

        get "api/action/:action_id/test" do
          summary "Subaction"
          warden_scope :visitor
          sections "some_action"
          action :action_cmd, **opts
          serializer :serializer, **opts
        end

        get "api/action/:action_id/test_override" do
          summary "Subaction"
          warden_scope :visitor
          sections "some_action"
          action :action_cmd, **opts
          serializer :serializer, **opts
          override do |r|
            r.json do
              r.response.status = 200
              "result"
            end
          end
        end

        get "api/action/:id/subaction" do
          summary "Subaction"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
        end

        post "api/action/:id/subaction" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
        end

        post "api/action/:id/anotheraction" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :another_cmd, **opts
          serializer :serializer, **opts
        end

        post "api/action/:id/subaction/:sub_id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :sub_cmd, **opts
          serializer :serializer, **opts
        end

        post "api/action/:id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
        end

        get "api/serializer_error" do
          summary "Action with serializer error"
          warden_scope :visitor
          sections "some_action"
          action :serializer_error_cmd, **opts
          serializer :serializer, **opts
        end

        get "check_warden" do
          summary "Action to check Warden scopes"
          warden_scope :user, :another_user
          sections "some_action"
          action :warden_scope_cmd, **opts
        end
      end
    end

    class VisitorStrategy < Warden::Strategies::Base
      include Ree::LinkDSL

      def valid?
        true
      end

      def authenticate!
        success!({user: "visitor"})
      end
    end

    class UserStrategy < Warden::Strategies::Base
      include Ree::LinkDSL

      def valid?
        params = request.params
        return true if !params["user"].nil?
      end

      def authenticate!
        success!({user: "user"})
      end
    end

    class AnotherUserStrategy < Warden::Strategies::Base
      include Ree::LinkDSL

      def valid?
        params = request.params
        return true if !params["another_user"].nil?
      end

      def authenticate!
        success!({user: "another_user"})
      end
    end

    Warden::Strategies.add(:visitor, VisitorStrategy)
    Warden::Strategies.add(:user, UserStrategy)
    Warden::Strategies.add(:another_user, AnotherUserStrategy)

    class TestApp < ReeRoda::App
      use Warden::Manager do |config|
        config.default_strategies :visitor
        config.default_scope = :visitor
        config.scope_defaults :visitor, strategies: [:visitor], store: false
        config.scope_defaults :user, strategies: [:user], store: false
        config.scope_defaults :another_user, strategies: [:another_user], store: false

        config.failure_app = -> (env) {
          [
            401,
            {"Content-Type" => "text/plain"},
            ["requires authentication"]
          ]
        }
      end

      plugin :ree_routes

      ree_routes ReeRodaTest::TestRoutes.new,
        api_url: "http://some.api.url:1337",
        swagger_url: "swagger"

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

  let(:app) { TestApp.app }

  it {
    get "health"
    expect(last_response.body).to eq("success")
    expect(last_response.status).to eq(200)
  }

  it {
    get "swagger"
    expect(last_response.status).to eq(200)

    get "api/v1/swagger"
    expect(last_response.status).to eq(404)
  }

  it {
    get "api/action/1/subaction"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("{\"result\":\"result\"}")

    get "api/action/1/test"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("{\"result\":\"action_cmd\"}")
  }

  it {
    get "api/action/:action_id/test_override"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("result")
  }

  it {
    post "api/action/1/subaction/2"
    expect(last_response.status).to eq(201)
    expect(last_response.body).to eq("{\"result\":\"another_result\"}")
  }

  it {
    post "api/action/1/anotheraction"
    expect(last_response.status).to eq(201)
    expect(last_response.body).to eq("{\"result\":\"another_result\"}")
  }

  it {
    get "api/action/not_integer"
    expect(last_response.status).to eq(400)
  }

  it {
    get "api/serializer_error"
    expect(last_response.status).to eq(500)
  }

  it {
    get "some_other_route"
    expect(last_response.status).to eq(200)
    expect(last_response.status).not_to eq(404)
  }

  it {
    # first scope is passed
    get "check_warden?user=hello"
    expect(last_response.status).to eq(200)

    # second scope is passed
    get "check_warden?another_user=hello"
    expect(last_response.status).to eq(200)

    # all scopes failed
    get "check_warden"
    expect(last_response.status).to eq(401)
  }
end
