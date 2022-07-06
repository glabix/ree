# frozen_string_literal: true

class ReeDatetime::SecondsDiff
  include Ree::FnDSL

  fn :seconds_diff do
    link :round_helper, from: :ree_number, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash
  end


  doc("Returns time difference in seconds")
  contract(
    Or[Date, DateTime, Time],
    Or[Date, DateTime, Time],
    Ksplat[
      round_mode?: Or[*ROUND_MODES]
    ] => Integer).throws(ArgumentError)
  def call(start_time, end_time, **opts)
    s_delta = end_time.to_time.to_i - start_time.to_time.to_i
    raise ArgumentError, "start_time bigger than end_time" if s_delta < 0
    s_delta
  end
end
