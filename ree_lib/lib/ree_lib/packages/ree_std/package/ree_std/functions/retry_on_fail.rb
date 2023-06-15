# frozen_string_literal: true

class ReeStd::RetryOnFail
  include Ree::FnDSL

  fn :retry_on_fail do
    link "ree_std/retry", -> { Retry }
  end

  doc(<<~DOC)
    ## **Ruby Function: retry_on_fail**

    This function allows you to execute a provided block of code and automatically retry it in case a specific exception occurs.

    rubyCopy code

    `x = 0 retry_on_fail(max: 2, retry_block: ->(attempt, e) { x += 1 } ) { 1 / x }`

    ## **Parameters**

    *   **max** (Integer, required): Specifies the maximum number of retry attempts.
    *   **interval** (Integer, optional, default: 1): Sets the base delay between retry attempts in seconds.
    *   **max_interval** (Integer, optional, default: Float::INFINITY): Defines the upper limit for the delay between retry attempts.
    *   **backoff_factor** (Integer, optional, default: 1): Determines the increasing factor for the delay based on the attempt number.
    *   **exceptions** (StandardError[], optional, default: [StandardError]): Specifies a list of exceptions that should trigger a retry.
    *   **retry_block** (Proc, optional, default: **Proc.new {|attempt_number, exception|}**): Allows you to provide a custom block of code to be executed after a failed attempt.
    *   **retry_if** (Proc, optional, default: **Proc.new { |exception| true }**): Provides an additional condition that must be satisfied before initiating a new retry attempt.
  DOC
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
    ],
    Block => nil
  )
  def call(max:, **opts, &block)
    Retry.new(max: max, **opts).call(&block)
  end
end