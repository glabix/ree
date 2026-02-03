package_require("ree_routes/dsl")

RSpec.describe ReeRoutes::DSL, type: [:autoclean] do
  before :all do
    Ree.enable_irb_mode

    module ReeRoutesTest
      include Ree::PackageDSL

      package
    end

    class ReeRoutesTest::EmptyRoutes
      include ReeRoutes::DSL

      routes :empty_routes do
      end
    end

    class ReeRoutesTest::Cmd
      include Ree::FnDSL

      fn :cmd

      def call
      end
    end

    class ReeRoutesTest::Serializer
      include ReeMapper::DSL

      mapper :serializer

      build_mapper.use(:serialize) do
        integer :id
      end
    end

    class ReeRoutesTest::Caster
      include ReeMapper::DSL

      mapper :caster

      build_mapper.use(:cast) do
        integer :id
      end
    end

    class ReeRoutesTest::Routes
      include ReeRoutes::DSL

      routes :routes do
        default_warden_scope :identity, :user

        post "users" do
          summary "Test route"
          action :cmd, from: :ree_routes_test
          serializer :serializer, from: :ree_routes_test
          warden_scope :identity, :user
          respond_to :json
        end

        get "files.csv" do
          summary "Test route"
          action :cmd, from: :ree_routes_test
          warden_scope :user
          respond_to :csv
        end
      end
    end
  end

  after :all do
    Ree.disable_irb_mode
  end

  it {
    expect(ReeRoutesTest::EmptyRoutes.new).to eq([])
  }

  it {
    routes = ReeRoutesTest::Routes.new

    expect(routes.size).to eq(2)

    post_route = routes.first
    csv_route = routes.last

    expect(post_route.serializer.name).to eq(:serializer)
    expect(post_route.action.name).to eq(:cmd)
    expect(post_route.respond_to).to eq(:json)

    expect(csv_route.respond_to).to eq(:csv)
  }
end
