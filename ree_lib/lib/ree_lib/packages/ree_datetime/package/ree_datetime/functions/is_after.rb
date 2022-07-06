# frozen_string_literal: true

class ReeDatetime::IsAfter
  include Ree::FnDSL

  fn :is_after

  doc("Returns true if the date_time_end falls after <tt>date_time_start</tt>.")
  contract(DateTime, DateTime => Bool)
  def call(date_time_start, date_time_end)
    date_time_end > date_time_start
  end
end