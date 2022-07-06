# frozen_string_literal: true

class ReeDatetime::IsBefore
  include Ree::FnDSL

  fn :is_before 

  doc("Returns true if the date_time_start falls before <tt>date_time_end</tt>.")
  contract(DateTime, DateTime => Bool)
  def call(date_time_start, date_time_end)
    date_time_start < date_time_end
  end
end