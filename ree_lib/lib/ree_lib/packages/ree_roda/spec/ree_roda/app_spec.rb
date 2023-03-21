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

      package
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

        get "api/action/:id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
        end

        get "api/action/:id/subaction" do
          summary "Subaction"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
        end

        post "api/action/:id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
          serializer :serializer, **opts
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

    Warden::Strategies.add(:visitor, VisitorStrategy)

    class TestApp < ReeRoda::App
      use Warden::Manager do |config|
        config.default_strategies :visitor
        config.default_scope = :visitor
        config.scope_defaults :visitor, strategies: [:visitor], store: false

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
  }
end