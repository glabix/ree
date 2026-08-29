# frozen_string_literal: true

class ReeDate::Tomorrow
  include Ree::FnDSL

  fn :tomorrow do
    link :today
    link :advance_date
  end

  doc("Returns a new date representing tomorrow.")
  contract(Nilor[Date] => Date)
  def call(date = nil)
    advance_date(date || today, days: 1)
  end
end