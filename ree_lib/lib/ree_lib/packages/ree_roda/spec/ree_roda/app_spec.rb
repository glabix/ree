require "rack/test"

package_require("ree_roda/app")
package_require("ree_actions/dsl")
package_require("ree_roda/plugins/ree_actions")

RSpec.describe ReeRoda::App do
  include Rack::Test::Methods

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

        get "api/action/:id" do
          summary "Some action"
          warden_scope :visitor
          sections "some_action"
          action :cmd, **opts
        end
      end
    end

    class TestApp < ReeRoda::App
      plugin :ree_actions

      ree_actions ReeRodaTest::TestActions.new,
        api_url: "http://some.api.url:1337",
        swagger_url: "swagger"

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
end