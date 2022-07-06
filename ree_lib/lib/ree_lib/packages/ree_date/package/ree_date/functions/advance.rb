# frozen_string_literal: true

class ReeDate::Advance
  include Ree::FnDSL

  fn :advance

  doc(<<~DOC)
    Provides precise Date calculations for years, months, quarters and days. The +options+ parameter takes a hash with
    any of these keys: <tt>:years</tt>, <tt>:months</tt>, <tt>:quarters </tt>, <tt>:weeks</tt>, <tt>:days</tt>.
  DOC
  contract(
    Date,
    Ksplat[
      years?: Integer,
      quarters?: Integer,
      months?: Integer,
      weeks?: Integer,
      days?: Integer
    ] => Date
  )
  def call(date, **opts)
    date = date >> opts[:years] * 12 if opts[:years]
    date = date >> opts[:quarters] * 3 if opts[:quarters]
    date = date >> opts[:months] if opts[:months]
    date = date + opts[:weeks] * 7 if opts[:weeks]
    date = date + opts[:days] if opts[:days]

    date
  end
end