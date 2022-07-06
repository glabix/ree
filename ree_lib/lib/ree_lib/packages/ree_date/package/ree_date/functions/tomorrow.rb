# frozen_string_literal: true

class ReeDate::Tomorrow
  include Ree::FnDSL

  fn :tomorrow do
    link :today
    link :advance
  end

  doc("Returns a new date representing tomorrow.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance(date || today, days: 1)
  end
end