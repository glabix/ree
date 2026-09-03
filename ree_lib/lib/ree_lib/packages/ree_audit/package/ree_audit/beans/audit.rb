# frozen_string_literal: true

class ReeAudit::Audit
  include Ree::BeanDSL

  bean :audit do
    singleton

    # The sink is injected once, at application boot: the package ships a null
    # sink and the host application swaps in its own. That single assignment is
    # the only mutation this object ever sees, so it must not be frozen.
    freeze false

    link :config
    link :filter_params
    link :logger, from: :ree_logger
    link 'ree_audit/sinks/null_sink', -> { NullSink }
  end

  MAX_ERROR_MESSAGE_LENGTH = 512

  def sink
    @sink ||= NullSink.new
  end

  def sink=(value)
    @sink = value
  end

  # Wraps one action call. Everything the trail needs that is only knowable
  # here — how it ended, how long it took, what the code annotated on the way —
  # is filled in around the yield.
  #
  # The exception itself is never swallowed: an audited route must behave
  # exactly like an unaudited one.
  def around(event)
    return yield if !config.enabled

    event.params = filter_params(event.params || {})
    event.started_at = Time.now
    started_monotonic = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    ReeAudit::Context.push(event)

    begin
      result = yield
      event.status = :ok
      result
    rescue StandardError => e
      event.status = denied?(e) ? :denied : :error
      event.error_type = e.class.name
      event.error_message = e.message.to_s[0, MAX_ERROR_MESSAGE_LENGTH]
      raise
    ensure
      event.duration_ms = (
        (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_monotonic) * 1000
      ).round
      ReeAudit::Context.pop
      write_safely(event) if event.recordable?
    end
  end

  private

  # A refusal to show client data is as much an audit fact as showing it.
  def denied?(e)
    e.is_a?(ReeErrors::Error) && e.type == :permission
  rescue StandardError
    false
  end

  # The trail must never be the reason a request fails.
  def write_safely(event)
    sink.write(event)
  rescue StandardError => e
    logger.error(
      "audit sink failed for #{event.action_name}",
      {action_name: event.action_name, status: event.status},
      e
    )
    nil
  end
end
