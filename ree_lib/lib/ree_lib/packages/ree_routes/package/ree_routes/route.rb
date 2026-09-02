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

  # Internal routes are audited unless told otherwise. `visibility` is
  # mandatory for admin paths (see DSL#define_route), so this list can never
  # drift away from the set of routes that actually touch client data — which a
  # hand-maintained list of audited routes inevitably would.
  def audited?
    @audit.nil? ? internal? : @audit
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
