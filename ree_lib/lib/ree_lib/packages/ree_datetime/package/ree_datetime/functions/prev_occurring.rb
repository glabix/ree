# frozen_string_literal: true

class ReeDatetime::PrevOccurring
  include Ree::FnDSL

  fn :prev_occurring do
    link :now
    link :change
    link :prev_occurring, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time representing the previous occurrence of the specified day of week.
    
      now                              # => Tue, 24 May 2022 13:15:20
      date_time (optional)                  # => Wed, 6  Apr 2022 13:15:20
      prev_occurring(date_time, :monday)    # => Mon, 28 Mar 2022 13:15:20
      prev_occurring(date_time, :thursday)  # => Thu, 31 Mar 2022 13:15:20
      prev_occurring(:thursday)        # => Thu, 19 May 2022 13:15:20
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
    
    change(
      prev_occurring(date_time, week_day),
      hour: date_time.hour,
      min: date_time.min,
      sec: date_time.sec
    )
  end
end