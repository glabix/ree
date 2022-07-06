# frozen_string_literal: true

class ReeDate::Yesterday
  include Ree::FnDSL

  fn :yesterday do
    link :today
    link :advance
  end

  doc("Returns a new date representing yesterday.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance(date || today, days: -1)
  end
end