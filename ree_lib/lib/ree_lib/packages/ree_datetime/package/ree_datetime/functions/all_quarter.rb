# frozen_string_literal: true

class ReeDatetime::AllQuarter
  include Ree::FnDSL

  fn :all_quarter do
    link :now
    link :beginning_of_quarter
    link :end_of_quarter
  end

  doc(<<~DOC)
    Returns a Range representing the whole quarter of the current date/time.
    If no date_time passed returns the whole current quarter.
  DOC
  contract(Nilor[DateTime] => RangeOf[DateTime])
  def call(date_time = nil)
    date_time = date_time || now
    beginning_of_quarter(date_time)..end_of_quarter(date_time)
  end
end