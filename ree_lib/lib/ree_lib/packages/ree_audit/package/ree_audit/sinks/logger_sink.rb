# frozen_string_literal: true

require_relative "sink"

# Development sink: dumps the event into the application log. Debug level on
# purpose — an audited call is written on every admin request.
class ReeAudit::LoggerSink < ReeAudit::Sink
  def initialize(logger)
    @logger = logger
  end

  def write(event)
    @logger.debug("audit: #{event.action_name}", event.to_h)
  end
end
