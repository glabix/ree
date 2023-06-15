# frozen_string_literal: true

class ReeStd::Retry
  contract(
    Kwargs[
      max: Integer,
    ],
    Ksplat[
      interval?: Integer,
      max_interval?: Integer,
      backoff_factor?: Integer,
      exceptions?: ArrayOf[SubclassOf[StandardError]],
      retry_block?: Proc,
      retry_if?: Proc,
    ] => Any
  )
  def initialize(max:, **opts)
    @max = max
    @current_attempt = 0

    @interval = opts.fetch(:interval, 1)
    @max_interval = opts.fetch(:max_interval, Float::INFINITY)
    @backoff_factor = opts.fetch(:backoff_factor, 1)

    @exceptions = opts.fetch(:exceptions) { [StandardError].freeze }
    @retry_block = opts.fetch(:retry_block, Proc.new {})
    @retry_if = opts.fetch(:retry_if, Proc.new { true })
  end

  contract(
    Block => Any
  )
  def call(&block)
    block.call
  rescue => e
    raise unless match_error?(e)
    raise unless has_attempts?

    @retry_block.call(@current_attempt, e)

    Kernel.sleep(calculate_retry_interval)

    increment_attemt!
    retry
  end

  private

  def has_attempts?
    @current_attempt < @max
  end

  def increment_attemt!
    @current_attempt += 1
  end

  def calculate_retry_interval
    current_interval = @interval * (@backoff_factor ** @current_attempt)

    [@max_interval, current_interval].min
  end

  def match_error?(e)
    puts @retry_if.call(e)
    @retry_if.call(e) && @exceptions.any? { e.is_a? _1 }
  end
end