# frozen_string_literal: true

class ReeDatetime::SecondsSince
  include Ree::FnDSL

  fn :seconds_since 

  doc("Returns a new date/time the specified number of seconds in the future.")
  contract(Nilor[DateTime], Integer => DateTime)
  def call(date_time = nil, seconds_count)
    date_time = date_time || DateTime.now
    date_time + Rational(seconds_count, 86400)
  end
end