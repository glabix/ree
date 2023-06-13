# frozen_string_literal: true

class ReeStd::RetryOnFail
  include Ree::FnDSL

  fn :retry_on_fail do
    link "ree_std/retry", -> { Retry }
  end

  doc(<<~DOC)
    Execute provided block of code and retry it in case of specific exception
    ```ruby
      x = 0

      retry_on_fail(
        max: 2,
        retry_block: ->(attempt, e) { x += 1 }
      ) { 1 / x }
    ```
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