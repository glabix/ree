# frozen_string_literal: true

class ReeDatetime::EndOfWeek
  include Ree::FnDSL

  fn :end_of_week do
    link :now
    link :change
    link :end_of_day    
    link :end_of_week, from: :ree_date
  end

  doc(<<~DOC)
    Returns a new date/time at the end of the week.
    If no date_time passed returns date/time at the end of the current week.
    
      date_time(optional) => Wed, 25 May 2022 13:00:00
      end_of_week(date_time, :monday) # => Sun, 29 May 2022 23:59:59.999999
      end_of_week(date_time, :sunday) # => Sat, 28 May 2022 23:59:59.999999
    Week is assumed to end on +week_start+ (monday or sunday).
  DOC
  contract(Nilor[DateTime], Or[:sunday, :monday] => DateTime)
  def call(date_time = nil, week_start)
    end_of_day(end_of_week((date_time || now), week_start)) 
  end
end