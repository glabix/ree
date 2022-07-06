# frozen_string_literal: true

class ReeDate::IsBefore
  include Ree::FnDSL

  fn :is_before

  doc("Returns true if the <tt>date_start</tt> falls before <tt>date_end</tt>.")
  contract(Date, Date => Bool)
  def call(date_start, date_end)
    date_start < date_end
  end
end