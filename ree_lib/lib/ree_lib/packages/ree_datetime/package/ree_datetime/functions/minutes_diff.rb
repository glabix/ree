# frozen_string_literal: true

class ReeDatetime::MinutesDiff
  include Ree::FnDSL

  fn :minutes_diff do
    link :round_helper, from: :ree_number, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash
  end

  MINUTE_SECONDS = 60.0

  doc("Returns time difference in minutes")
  contract(
    Or[Date, DateTime, Time],
    Or[Date, DateTime, Time],
    Ksplat[
      round_mode?: Or[*ROUND_MODES]
    ] => Integer).throws(ArgumentError)
  def call(start_time, end_time, **opts)
    s_delta = end_time.to_time.to_i - start_time.to_time.to_i

    raise ArgumentError, "start_time bigger than end_time" if s_delta < 0

    m_delta = s_delta / MINUTE_SECONDS
    opts[:precision] = 0

    round_helper(
      m_delta, **slice(opts, [:precision, :round_mode])
    ).to_i
  end
end

