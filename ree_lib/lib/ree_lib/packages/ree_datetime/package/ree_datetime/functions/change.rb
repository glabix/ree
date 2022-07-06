# frozen_string_literal: true

class ReeDatetime::Change
  include Ree::FnDSL

  fn :change 

  doc(<<~DOC)
    Returns a new date/time where one or more of the elements have been changed
    according to the +opts+ parameter.
  DOC

  contract(
    DateTime,
    Ksplat[
      year?: Integer,
      month?: Integer,
      day?: Integer,
      hour?: Integer,
      min?: Integer,
      sec?: Integer,
      nsec?: Integer,
      usec?: Integer,
      offset?: Rational,
    ] => DateTime
  ).throws(ArgumentError)
  def call(date_time, **opts)
    if opts[:nsec]
      raise ArgumentError, "Can't change both :nsec and :usec at the same time" if opts[:usec]
      new_fraction = Rational(opts[:nsec], 1000000000).to_f
      raise ArgumentError, "argument out of range" if new_fraction >= 1
    elsif opts[:usec]
      new_fraction = Rational(opts[:usec], 1000000).to_f
      raise ArgumentError, "argument out of range" if new_fraction >= 1
    end

    DateTime.new(
      opts[:year] || date_time.year,
      opts[:month] || date_time.month,
      opts[:day] || date_time.day,
      opts[:hour] || date_time.hour,
      opts[:min] || date_time.min,
      (opts[:sec] || date_time.sec).to_f + (new_fraction || 0),
      opts[:offset] || date_time.offset
    )
  end
end