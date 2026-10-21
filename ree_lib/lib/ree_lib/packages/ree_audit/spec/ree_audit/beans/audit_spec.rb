# frozen_string_literal: true

package_require('ree_audit/beans/audit')
package_require('ree_audit/event')
package_require('ree_errors/permission_error')
package_require('ree_errors/not_found_error')

RSpec.describe :audit do
  link :audit, from: :ree_audit
  link :config, from: :ree_audit
  link :permission_error, from: :ree_errors
  link :not_found_error, from: :ree_errors
  link :logger, from: :ree_logger

  # Captures what the application would have persisted.
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

  let(:broken_sink) {
    Class.new(ReeAudit::Sink) do
      def write(event)
        raise StandardError.new("sink is down")
      end
    end.new
  }

  let(:event) {
    ReeAudit::Event.build(
      action_name: :admin_users_query,
      package_name: :accounts,
      summary: "List users",
      sections: ["Admin"],
      request_method: :get,
      path: "api/v1/accounts/admin/users",
      request_path: "/api/v1/accounts/admin/users",
      params: {page: 1, token: "secret"},
      accessor: Object.new
    )
  }

  before do
    ReeAudit::Context.clear
    audit.sink = test_sink
  end

  after do
    audit.sink = ReeAudit::NullSink.new
    ReeAudit::Context.clear
  end

  it "writes a successful call and returns the action result" do
    result = audit.around(event) { :action_result }

    expect(result).to eq(:action_result)
    expect(test_sink.events.size).to eq(1)

    written = test_sink.events.first
    expect(written.status).to eq(:ok)
    expect(written.action_name).to eq(:admin_users_query)
    expect(written.error_type).to be_nil
    expect(written.started_at).to be_a(Time)
    expect(written.duration_ms).to be >= 0
  end

  it "filters secrets out of the params before they reach the sink" do
    audit.around(event) { :ok }

    expect(test_sink.events.first.params).to eq({page: 1, token: 'FILTERED'})
  end

  it "records a permission refusal and lets the error through" do
    klass = permission_error(:no_access)

    expect {
      audit.around(event) { raise klass.new("not allowed") }
    }.to raise_error(klass, "not allowed")

    written = test_sink.events.first
    expect(written.status).to eq(:denied)
    expect(written.error_message).to eq("not allowed")
  end

  # 404 предметной области — обычный исход, а не поломка: строка «нечего
  # показать» в отчёте соответствия не должна читаться как сбой.
  it "records a domain not-found as its own outcome, not as a failure" do
    klass = not_found_error(:missing)

    expect {
      audit.around(event) { raise klass.new("nothing here") }
    }.to raise_error(klass)

    expect(test_sink.events.first.status).to eq(:not_found)
  end

  it "records an arbitrary failure as an error and lets it through" do
    expect {
      audit.around(event) { raise ArgumentError.new("boom") }
    }.to raise_error(ArgumentError, "boom")

    written = test_sink.events.first
    expect(written.status).to eq(:error)
    expect(written.error_type).to eq("ArgumentError")
    expect(written.error_message).to eq("boom")
  end

  it "survives a broken sink: the request completes, the failure is logged" do
    audit.sink = broken_sink

    expect(logger).to receive(:error).at_least(:once)

    expect(audit.around(event) { :action_result }).to eq(:action_result)
  end

  it "keeps nested calls on a stack" do
    inner_event = ReeAudit::Event.build(action_name: :inner_query)
    seen = []

    audit.around(event) do
      seen << ReeAudit::Context.current.action_name

      audit.around(inner_event) do
        seen << ReeAudit::Context.current.action_name
        :inner
      end

      seen << ReeAudit::Context.current.action_name
      :outer
    end

    expect(seen).to eq([:admin_users_query, :inner_query, :admin_users_query])
    expect(ReeAudit::Context.current).to be_nil
    expect(test_sink.events.map(&:action_name)).to eq([:inner_query, :admin_users_query])
  end

  it "costs nothing when audit is disabled" do
    allow(config).to receive(:enabled).and_return(false)

    result = audit.around(event) {
      expect(ReeAudit::Context.current).to be_nil
      :action_result
    }

    expect(result).to eq(:action_result)
    expect(test_sink.events).to be_empty
  end

  it "annotates the event from inside the call" do
    audit.around(event) do
      ReeAudit.annotate(permission: :access_uploads, organization_id: 42)
      ReeAudit.annotate(subject: {type: :upload, id: "abc"})
      :ok
    end

    expect(test_sink.events.first.annotations).to eq({
      permission: :access_uploads,
      organization_id: 42,
      subject: {type: :upload, id: "abc"}
    })
  end

  it "ignores an annotation made outside an audited call" do
    expect(ReeAudit.annotate(permission: :access_uploads)).to be_nil
  end

  context "an :on_annotation event" do
    let(:event) {
      ReeAudit::Event.build(action_name: :balance_query, on_annotation: true)
    }

    it "drops the call nobody annotated" do
      result = audit.around(event) { :action_result }

      expect(result).to eq(:action_result)
      expect(test_sink.events).to be_empty
    end

    it "writes the call the action annotated" do
      audit.around(event) do
        ReeAudit.annotate(platform_admin_id: 7)
        :action_result
      end

      expect(test_sink.events.size).to eq(1)
      expect(test_sink.events.first.annotations).to eq({platform_admin_id: 7})
    end

    it "writes a refusal that was annotated before the raise" do
      klass = permission_error(:no_access)

      expect {
        audit.around(event) do
          ReeAudit.annotate(platform_admin_id: 7)
          raise klass.new("not allowed")
        end
      }.to raise_error(klass)

      expect(test_sink.events.size).to eq(1)
      expect(test_sink.events.first.status).to eq(:denied)
    end
  end
end
