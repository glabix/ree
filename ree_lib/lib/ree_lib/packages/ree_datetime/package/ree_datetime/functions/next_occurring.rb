# frozen_string_literal: true

class ReeDatetime::NextOccurring
  include Ree::FnDSL

  fn :next_occurring do
    link :now
    link :change
    link :next_occurring, from: :ree_date
  end

  doc(<<~DOC)
  # Returns a new date/time representing the next occurrence of the specified day of week.
  # 
  #   now                              # => Tue, 24 May 2022 13:15:20
  #   date_time (optional)                  # => Thu, 14 Dec 2017 13:15:20
  #   next_occurring(date_time, :monday)    # => Mon, 18 Dec 2017 13:15:20
  #   next_occurring(date_time, :thursday)  # => Thu, 21 Dec 2017 13:15:20
  #   next_occurring(:thursday)        # => Thu, 2  Jun 2022 13:15:20
  DOC
  contract(
    Nilor[DateTime], 
    Or[
      :monday,
      :tuesday, 
      :wednesday, 
      :thursday, 
      :friday, 
      :saturday, 
      :sunday
    ] => DateTime
  )
  def call(date_time = nil, week_day)
    date_time = date_time || now
    change(next_occurring(date_time, week_day), hour: date_time.hour, min: date_time.min, sec: date_time.sec)
  end
end