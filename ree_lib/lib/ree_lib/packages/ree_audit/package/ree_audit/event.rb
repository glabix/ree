# frozen_string_literal: true

# One audited action call. Built by the transport layer (the ree_roda plugin),
# enriched by the application through ReeAudit.annotate, and handed to a sink
# once the call is over.
class ReeAudit::Event
  STATUSES = [:ok, :denied, :error].freeze

  attr_accessor :action_name, :package_name, :summary, :sections,
                :request_method, :path, :request_path, :params, :accessor,
                :status, :error_type, :error_message, :started_at,
                :duration_ms, :annotations

  class << self
    # Keyword-only on purpose: callers live in another package and must not
    # depend on the order of the fields here.
    def build(
      action_name:,
      package_name: nil,
      summary: nil,
      sections: [],
      request_method: nil,
      path: nil,
      request_path: nil,
      params: {},
      accessor: nil
    )
      event = new

      event.action_name = action_name
      event.package_name = package_name
      event.summary = summary
      event.sections = sections || []
      event.request_method = request_method
      event.path = path
      event.request_path = request_path
      event.params = params || {}
      event.accessor = accessor
      event.annotations = {}

      event
    end
  end

  def initialize
    @sections = []
    @params = {}
    @annotations = {}
    @status = :ok
  end

  def ok?
    status == :ok
  end

  def denied?
    status == :denied
  end

  def to_h
    {
      action_name: action_name,
      package_name: package_name,
      summary: summary,
      sections: sections,
      request_method: request_method,
      path: path,
      request_path: request_path,
      params: params,
      status: status,
      error_type: error_type,
      error_message: error_message,
      started_at: started_at,
      duration_ms: duration_ms,
      annotations: annotations
    }
  end
end
