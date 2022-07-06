# frozen_string_literal: true

class ReeDate::Change
  include Ree::FnDSL

  fn :change

  doc(<<~DOC)
    Returns a new date where one or more of the elements have been changed
    according to the +opts+ parameter.
  DOC
  
  contract(
    Date,
    Ksplat[
      year?: Integer,
      month?: Integer,
      day?: Integer
    ] => Date
  )
  def call(date, **opts)
    Date.new(
      opts[:year] || date.year,
      opts[:month] || date.month,
      opts[:day] || date.day
    )
  end
end