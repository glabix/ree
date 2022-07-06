# frozen_string_literal: true

class ReeDatetime::BeginningOfWeek
  include Ree::FnDSL

  fn :beginning_of_week do
    link :now
    link :change
    link :beginning_of_day    
    link :beginning_of_week, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the start of the week.
    If no date_time passed returns date/time at the start of the current week.
    
      date_time(optional) => Wed, 25 May 2022 13:00:00
      beginning_of_week(date_time, :monday) # => Mon, 23 May 2022 00:00:00
      beginning_of_week(date_time, :sunday) # => Sun, 22 May 2022 00:00:00
    Week is assumed to start on +week_start+ (monday or sunday).
  DOC
  contract(Nilor[DateTime], Or[:sunday, :monday] => DateTime)
  def call(date_time = nil, week_start)
    beginning_of_day(beginning_of_week((date_time || now), week_start)) 
  end
end