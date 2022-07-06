# frozen_string_literal: true

class ReeDatetime::AllMonth
  include Ree::FnDSL

  fn :all_month do
    link :now
    link :beginning_of_month
    link :end_of_month
  end

  doc(<<~DOC)
    Returns a Range representing the whole month of the current date/time.
    If no date_time passed returns the whole current month.
  DOC
  contract(Nilor[DateTime] => RangeOf[DateTime])
  def call(date_time = nil)
    date_time = date_time || now
    beginning_of_month(date_time)..end_of_month(date_time)
  end
end