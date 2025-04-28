# frozen_string_literal: true

class ReeDate::Yesterday
  include Ree::FnDSL

  fn :yesterday do
    link :today
    link :advance_date
  end

  doc("Returns a new date representing yesterday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, days: -1)
  end
end