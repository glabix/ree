class ReeDatetime::GeneralDiff
  include Ree::FnDSL

  fn :general_diff do
    link :round_helper, from: :ree_number, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash

    link :years_diff
    link :months_diff
    link :weeks_diff
    link :days_diff
    link :hours_diff
    link :minutes_diff
    link :seconds_diff
  end

  INTERVALS = [:years, :months, :weeks, :days, :hours, :minutes, :seconds]
  SECONDS_IN_INTERVAL = INTERVALS.zip([365 * 24 * 60 * 60, 30 * 24 * 60 * 60, 7 * 24 * 60 * 60, 24 * 60 * 60, 60 * 60, 60, 1]).to_h

  doc("Returns time difference in human readable representation (hash)")
  contract(
    Or[Date, DateTime, Time],
    Or[Date, DateTime, Time],
    Ksplat[
      round_mode?: Or[*ROUND_MODES]
    ] => HashOf[Or[*INTERVALS], Integer]).throws(ArgumentError)
  def call(start_time, end_time, **opts)
    results = []
    end_time = end_time.to_time

    opts = slice(opts, [:round_mode])

    y_delta = years_diff(start_time, end_time, **opts)
    results << y_delta

    past_time = start_time.to_time + y_delta * SECONDS_IN_INTERVAL[:years]

    m_delta = end_time > past_time ? months_diff(past_time, end_time, **opts) : 0
    results << m_delta
    past_time += m_delta * SECONDS_IN_INTERVAL[:months]

    w_delta = end_time > past_time ? weeks_diff(past_time, end_time, **opts) : 0
    results << w_delta
    past_time += w_delta * SECONDS_IN_INTERVAL[:weeks]

    d_delta = end_time > past_time ? days_diff(past_time, end_time, **opts) : 0
    results << d_delta
    past_time += d_delta * SECONDS_IN_INTERVAL[:days]

    h_delta = end_time > past_time ? hours_diff(past_time, end_time, **opts) : 0
    results << h_delta
    past_time += h_delta * SECONDS_IN_INTERVAL[:hours]

    m_delta = end_time > past_time ? minutes_diff(past_time, end_time, **opts) : 0
    results << m_delta
    past_time += m_delta * SECONDS_IN_INTERVAL[:minutes]

    s_delta = end_time > past_time ? seconds_diff(past_time, end_time, **opts) : 0
    results << s_delta * SECONDS_IN_INTERVAL[:seconds]

    Hash[INTERVALS.zip(results)]
  end
end
