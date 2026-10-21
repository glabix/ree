require "rack/test"

package_require("ree_roda/app")
package_require("ree_actions/dsl")
package_require("ree_routes/dsl")
package_require("ree_roda/plugins/ree_routes")
package_require("ree_audit/beans/audit")

require "warden"

RSpec.describe "ree_routes audit" do
  include Rack::Test::Methods

  link :audit, from: :ree_audit

  before :all do
    Ree.enable_irb_mode

    module ReeRodaAuditTest
      include Ree::PackageDSL

      package do
        depends_on :ree_actions
        depends_on :ree_errors
      end
    end

    class ReeRodaAuditTest::OkCmd
      include ReeActions::DSL

      action :ok_cmd

      def call(access, attrs)
        {result: "ok"}
      end
    end

    class ReeRodaAuditTest::DeniedCmd
      include ReeActions::DSL

      action :denied_cmd do
        link :permission_error, from: :ree_errors
      end

      PermissionErr = permission_error(:no_access, msg: "not allowed")

      def call(access, attrs)
        raise PermissionErr
      end
    end

    # Клиентская ручка глазами сотрудника: код опознаёт служебное обращение и
    # помечает его аннотацией.
    class ReeRodaAuditTest::StaffCmd
      include ReeActions::DSL

      action :staff_cmd

      def call(access, attrs)
        ReeAudit.annotate(staff_id: 42)
        {result: "ok"}
      end
    end

    class ReeRodaAuditTest::DeniedStaffCmd
      include ReeActions::DSL

      action :denied_staff_cmd do
        link :permission_error, from: :ree_errors
      end

      PermissionErr = permission_error(:no_access, msg: "not allowed")

      def call(access, attrs)
        ReeAudit.annotate(staff_id: 42)
        raise PermissionErr
      end
    end

    class ReeRodaAuditTest::BoomCmd
      include ReeActions::DSL

      action :boom_cmd

      def call(access, attrs)
        raise ArgumentError.new("boom")
      end
    end

    class ReeRodaAuditTest::Routes
      include ReeRoutes::DSL

      opts = {from: :ree_roda_audit_test}

      routes :routes do
        default_warden_scope :audit_visitor

        get "api/internal_default" do
          summary "Internal route"
          sections "Admin"
          visibility :internal
          audit true
          action :ok_cmd, **opts
        end

        get "api/internal_undeclared" do
          summary "Internal route that never mentions audit"
          sections "Admin"
          visibility :internal
          action :ok_cmd, **opts
        end

        get "api/internal_silenced" do
          summary "Internal route we do not want in the trail"
          sections "Admin"
          visibility :internal
          audit false
          action :ok_cmd, **opts
        end

        get "api/public_default" do
          summary "Public route"
          sections "Public"
          action :ok_cmd, **opts
        end

        get "api/public_audited" do
          summary "Public route touching someone else's data"
          sections "Public"
          audit true
          action :ok_cmd, **opts
        end

        get "api/on_annotation_client" do
          summary "Client reading its own data"
          sections "Public"
          audit :on_annotation
          action :ok_cmd, **opts
        end

        get "api/on_annotation_staff" do
          summary "Staff reading someone else's data"
          sections "Public"
          audit :on_annotation
          action :staff_cmd, **opts
        end

        get "api/on_annotation_staff_denied" do
          summary "Staff refused someone else's data"
          sections "Public"
          audit :on_annotation
          action :denied_staff_cmd, **opts
        end

        get "api/internal_denied" do
          summary "Internal route refusing access"
          sections "Admin"
          visibility :internal
          audit true
          action :denied_cmd, **opts
        end

        get "api/internal_boom" do
          summary "Internal route blowing up"
          sections "Admin"
          visibility :internal
          audit true
          action :boom_cmd, **opts
        end
      end
    end

    class AuditVisitorStrategy < Warden::Strategies::Base
      include Ree::LinkDSL

      def valid?
        true
      end

      def authenticate!
        success!({user: "visitor"})
      end
    end

    Warden::Strategies.add(:audit_visitor, AuditVisitorStrategy)

    audit_bean = audit

    # Class.new keeps `audit_bean` in scope; a `class` keyword would open a new
    # lexical scope and lose it.
    audited_app = Class.new(ReeRoda::App) do
      use Warden::Manager do |config|
        config.default_strategies :audit_visitor
        config.default_scope = :audit_visitor
        config.scope_defaults :audit_visitor, strategies: [:audit_visitor], store: false

        config.failure_app = -> (env) {
          [401, {"Content-Type" => "text/plain"}, ["requires authentication"]]
        }
      end

      plugin :ree_routes, audit: audit_bean

      ree_routes ReeRodaAuditTest::Routes.new, api_url: "http://some.api.url:1337"

      route do |r|
        r.ree_routes
      end
    end

    Object.const_set(:AuditedTestApp, audited_app)

    # Same routes, no `audit:` option — the regression guard for every other
    # project running on ree_lib.
    plain_app = Class.new(ReeRoda::App) do
      use Warden::Manager do |config|
        config.default_strategies :audit_visitor
        config.default_scope = :audit_visitor
        config.scope_defaults :audit_visitor, strategies: [:audit_visitor], store: false

        config.failure_app = -> (env) {
          [401, {"Content-Type" => "text/plain"}, ["requires authentication"]]
        }
      end

      plugin :ree_routes

      ree_routes ReeRodaAuditTest::Routes.new, api_url: "http://some.api.url:1337"

      route do |r|
        r.ree_routes
      end
    end

    Object.const_set(:PlainTestApp, plain_app)
  end

  after :all do
    Ree.disable_irb_mode
  end

  let(:test_sink) {
    Class.new(ReeAudit::Sink) do
      attr_reader :events

      def initialize
        @events = []
      end

      def write(event)
        @events << event
      end
    end.new
  }

  let(:app) { AuditedTestApp.app }

  before {
    audit.sink = test_sink
    ReeAudit::Context.clear
  }

  after {
    audit.sink = ReeAudit::NullSink.new
    ReeAudit::Context.clear
  }

  it "writes an internal route to the trail" do
    get "api/internal_default"

    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("{}")

    expect(test_sink.events.size).to eq(1)

    event = test_sink.events.first
    expect(event.action_name).to eq(:ok_cmd)
    expect(event.package_name).to eq(:ree_roda_audit_test)
    expect(event.status).to eq(:ok)
    expect(event.sections).to eq(["Admin"])
    expect(event.request_method).to eq(:get)
    expect(event.path).to eq("api/internal_default")
    expect(event.request_path).to eq("/api/internal_default")
    expect(event.accessor).to eq({user: "visitor"})
  end

  it "leaves an internal route that never declared audit out of the trail" do
    get "api/internal_undeclared"

    expect(last_response.status).to eq(200)
    expect(test_sink.events).to be_empty
  end

  it "leaves a silenced internal route out of the trail" do
    get "api/internal_silenced"

    expect(last_response.status).to eq(200)
    expect(test_sink.events).to be_empty
  end

  it "leaves a public route out of the trail" do
    get "api/public_default"

    expect(last_response.status).to eq(200)
    expect(test_sink.events).to be_empty
  end

  it "writes a public route that asked to be audited" do
    get "api/public_audited"

    expect(last_response.status).to eq(200)
    expect(test_sink.events.size).to eq(1)
    expect(test_sink.events.first.status).to eq(:ok)
  end

  it "leaves an unannotated :on_annotation route out of the trail" do
    get "api/on_annotation_client"

    expect(last_response.status).to eq(200)
    expect(test_sink.events).to be_empty
  end

  it "writes an :on_annotation route once the action annotated it" do
    get "api/on_annotation_staff"

    expect(last_response.status).to eq(200)
    expect(test_sink.events.size).to eq(1)
    expect(test_sink.events.first.annotations).to eq({staff_id: 42})
  end

  # Отказ сотруднику — такой же факт журнала, как и показ данных: аннотация
  # успевает лечь до того, как действие бросит исключение.
  it "writes an annotated :on_annotation route that ended in a refusal" do
    get "api/on_annotation_staff_denied"

    expect(last_response.status).to eq(403)
    expect(test_sink.events.size).to eq(1)
    expect(test_sink.events.first.status).to eq(:denied)
  end

  it "records a refusal and still answers 403" do
    get "api/internal_denied"

    expect(last_response.status).to eq(403)

    event = test_sink.events.first
    expect(event.status).to eq(:denied)
    expect(event.error_message).to eq("not allowed")
  end

  it "records a failure and still lets the error handler answer 500" do
    get "api/internal_boom"

    expect(last_response.status).to eq(500)

    event = test_sink.events.first
    expect(event.status).to eq(:error)
    expect(event.error_type).to eq("ArgumentError")
  end

  context "an application that never asked for audit" do
    let(:app) { PlainTestApp.app }

    it "behaves exactly as before" do
      get "api/internal_default"

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq("{}")
      expect(test_sink.events).to be_empty
    end
  end
end
