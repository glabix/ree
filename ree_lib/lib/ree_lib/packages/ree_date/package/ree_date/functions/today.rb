# frozen_string_literal: true

class ReeDate::Today
  include Ree::FnDSL

  fn :today

  doc("Returns a new date representing today.")
  contract(None => Date)
  def call
    Date.today
  end
end