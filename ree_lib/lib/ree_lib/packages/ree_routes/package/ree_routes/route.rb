# frozen_string_literal: true

class ReeRoutes::Route
  attr_accessor :summary, :request_method, :serializer, :respond_to,
                :sections, :action, :route, :warden_scopes, :path, :override,
                :visibility

  # Routing always includes every route; visibility only affects generated docs.
  def public?
    visibility.nil? || visibility == :public
  end

  def internal?
    !public?
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
