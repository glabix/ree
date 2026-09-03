# frozen_string_literal: true

class ReeRoutes::Route
  attr_accessor :summary, :request_method, :serializer, :respond_to,
                :sections, :action, :route, :warden_scopes, :path, :override,
                :visibility, :before, :redirect

  attr_writer :audit

  # Routing always includes every route; visibility only affects generated docs.
  def public?
    visibility.nil? || visibility == :public
  end

  def internal?
    !public?
  end

  # Auditing is declared at the route and nowhere else. Deriving it from
  # `visibility` would work just as well and read far worse: whether a call
  # lands in the access trail is exactly the kind of fact that must be visible
  # where the route is written, not inferred from a flag that means something
  # else. `audit` is mandatory on admin paths (see DSL#define_route), so the
  # audited set still cannot drift away from the routes that touch client data.
  def audited?
    @audit == true || @audit == :on_annotation
  end

  def audit_declared?
    !@audit.nil?
  end

  # `audit :on_annotation` — a public route that the client calls for its own
  # data and a staff member calls for someone else's. The event is always
  # assembled, but it only reaches the sink if the code annotated the call;
  # auditing such a route unconditionally would bury the staff access under
  # every ordinary client request.
  def audit_on_annotation?
    @audit == :on_annotation
  end

  def valid?
    !action.nil? && !summary.nil? && !warden_scopes.nil? && !warden_scopes.empty?
  end

  def warden_scopes=(scopes)
    @warden_scopes = Array(scopes)
  end

  def warden_scope
    @warden_scopes&.first
  end

  def warden_scope=(scope)
    @warden_scopes = Array(scope)
  end
end
