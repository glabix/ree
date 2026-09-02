# frozen_string_literal: true

require_relative "sink"

# Default sink: an application that never configured one gets no audit trail
# rather than an exception.
class ReeAudit::NullSink < ReeAudit::Sink
  def write(event)
    nil
  end
end
