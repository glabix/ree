# frozen_string_literal: true

# Destination of finished audit events. A host application implements one and
# hands it to the ree_roda plugin; the package itself never knows where the
# trail is stored.
class ReeAudit::Sink
  def write(event)
    raise NotImplementedError, "should be implemented in derived class"
  end
end
