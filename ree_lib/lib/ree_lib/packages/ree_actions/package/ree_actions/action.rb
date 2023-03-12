# frozen_string_literal: true

class ReeActions::Action
  attr_accessor :summary, :request_method, :serializer, :respond_to,
                :sections, :action, :warden_scope, :path

  def valid?
    !@action.nil? && !summary.nil? && !warden_scope.nil?
  end
end