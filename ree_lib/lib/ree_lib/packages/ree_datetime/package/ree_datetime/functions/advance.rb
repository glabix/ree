# frozen_string_literal: true

class ReeDatetime::Advance
  include Ree::FnDSL

  fn :advance do
    link :change
    link :seconds_since
    link :slice, from: :ree_hash
    link :advance, from: :ree_date
  end

  doc(<<~DOC)
    Uses DateTime to provide precise Time calculations for years, months, and days.
    The +options+ parameter takes any of these keys: <tt>:years</tt>,
    <tt>:months</tt>, <tt>:quarters</tt>, <tt>:weeks</tt>, <tt>:days</tt>, <tt>:hours</tt>,
    <tt>:minutes</tt>, <tt>:seconds</tt>.
  DOC
  contract(
    DateTime,
    Ksplat[
      years?: Integer,
      quarters?: Integer,
      months?: Integer,
      weeks?: Integer,
      days?: Integer,
      hours?: Integer,
      minutes?: Integer,
      seconds?: Integer
    ] => DateTime
  )
  def call(date_time, **opts)
    changed_date = advance(
      date_time.to_date,
      **slice(opts, :years, :months, :quarters, :weeks, :days)
    )

    datetime_advanced_by_date = change(
      date_time,
      year: changed_date.year,
      month: changed_date.month,
      day: changed_date.day
    )

    seconds_to_advance = (opts[:seconds] || 0) + (opts[:minutes] ||0) * 60 + (opts[:hours] || 0) * 3600

    if seconds_to_advance.zero?
      datetime_advanced_by_date
    else
      datetime_advanced_by_date = seconds_since(
        datetime_advanced_by_date, seconds_to_advance
      )
    end
  end
end