# frozen_string_literal: true

class ReeRoutes::Route
  attr_accessor :summary, :request_method, :serializer, :respond_to,
                :sections, :action, :route, :warden_scope, :path, :override

  def valid?
    !action.nil? && !summary.nil? && !warden_scope.nil?
  end
end