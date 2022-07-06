# frozen_string_literal: true

class ReeDate::IsAfter
  include Ree::FnDSL

  fn :is_after

  doc("Returns true if the <tt>date_end</tt> falls after <tt>date_start</tt>.")
  contract(Date, Date => Bool)
  def call(date_start, date_end)
    date_end > date_start
  end
end