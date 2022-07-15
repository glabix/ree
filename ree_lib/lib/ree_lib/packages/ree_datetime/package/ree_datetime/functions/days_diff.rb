# frozen_string_literal: true

class ReeDatetime::DaysDiff
  include Ree::FnDSL

  fn :days_diff do
    link :round_helper, from: :ree_number, import: -> { ROUND_MODES }
    link :slice, from: :ree_hash
  end

  DAY_SECONDS = 60.0 * 60 * 24

  doc("Returns time difference in days (24 hours range)")
  contract(
    Or[Date, DateTime, Time],
    Or[Date, DateTime, Time],
    Ksplat[
      round_mode?: Or[*ROUND_MODES]
    ] => Integer
  ).throws(ArgumentError)
  def call(start_time, end_time, **opts)
    s_delta = end_time.to_time.to_i - start_time.to_time.to_i

    raise ArgumentError, "start_time bigger than end_time" if s_delta < 0

    d_delta = s_delta / DAY_SECONDS
    opts[:precision] = 0

    round_helper(
      d_delta,
      **slice(opts, [:precision, :round_mode])
    ).to_i
  end
end


