# frozen_string_literal: true

package_require("ree_errors/validation_error")

RSpec.describe :build_swagger_from_routes do
  link :add_load_path, from: :ree_i18n
  link :build_swagger_from_routes, from: :ree_roda

  before :all do
    add_load_path(Dir[File.join(__dir__, 'locales/*.yml')])

    Ree.enable_irb_mode

    module ReeRodaTestSwagger
      include Ree::PackageDSL

      package do
        depends_on :ree_actions
        depends_on :ree_dao
      end
    end

    class ReeRodaTestSwagger::Cmd
      include ReeActions::DSL

      action :cmd

      ActionCaster = build_mapper.use(:cast) do
        integer :id
      end

      InvalidErr = ReeErrors::ValidationError.build(:invalid, "invalid")

      contract(Any, Any => Any).throws(InvalidErr)
      def call(access, attrs)
        raise InvalidErr if false
      end
    end

    class ReeRodaTestSwagger::TestRoutes
      include ReeRoutes::DSL

      routes :test_routes do
        default_warden_scope :identity
        opts = { from: :ree_roda_test_swagger }

        post "api/actions" do
          summary "Some action"
          action :cmd, **opts
        end
      end
    end

    class TestSwaggerApp < ReeRoda::App
      plugin :ree_routes

      ree_routes ReeRodaTestSwagger::TestRoutes.new

      route do |r|
        r.ree_routes
      end
    end
  end

  after :all do
    Ree.disable_irb_mode
  end

  let(:routes) { TestSwaggerApp.instance_variable_get(:@ree_routes) }

  it {
    swagger = build_swagger_from_routes(routes, "test", "test", "1.0", "https://example.com")

    expect(swagger.dig(:paths, "/api/actions", :post, :responses, 422, :description))
      .to eq("- type: **validation**, code: **invalid**, message: **invalid**")
  }
end