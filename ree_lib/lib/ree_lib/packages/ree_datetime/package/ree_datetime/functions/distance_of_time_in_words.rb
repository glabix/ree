# frozen_string_literal: true

class ReeDatetime::DistanceOfTimeInWords
  include Ree::FnDSL

  fn :distance_of_time_in_words do
    link :t, from: :ree_i18n
  end

  MINUTES_IN_YEAR = 525600
  MINUTES_IN_QUARTER_YEAR = 131400
  MINUTES_IN_THREE_QUARTERS_YEAR = 394200

  DEFAULT = {
    include_seconds: false,
    locale: :en
  }
  
  doc(<<~DOC)
    Reports the approximate distance in time between two Time, Date, or DateTime objects or integers as seconds.
    Pass <tt>include_seconds: true</tt> if you want more detailed approximations when distance < 1 min, 29 secs.
    Distances are reported based on the following table:
    
      0 <-> 29 secs                                                             # => less than a minute
      30 secs <-> 1 min, 29 secs                                                # => 1 minute
      1 min, 30 secs <-> 44 mins, 29 secs                                       # => [2..44] minutes
      44 mins, 30 secs <-> 89 mins, 29 secs                                     # => about 1 hour
      89 mins, 30 secs <-> 23 hrs, 59 mins, 29 secs                             # => about [2..24] hours
      23 hrs, 59 mins, 30 secs <-> 41 hrs, 59 mins, 29 secs                     # => 1 day
      41 hrs, 59 mins, 30 secs  <-> 29 days, 23 hrs, 59 mins, 29 secs           # => [2..29] days
      29 days, 23 hrs, 59 mins, 30 secs <-> 44 days, 23 hrs, 59 mins, 29 secs   # => about 1 month
      44 days, 23 hrs, 59 mins, 30 secs <-> 59 days, 23 hrs, 59 mins, 29 secs   # => about 2 months
      59 days, 23 hrs, 59 mins, 30 secs <-> 1 yr minus 1 sec                    # => [2..12] months
      1 yr <-> 1 yr, 3 months                                                   # => about 1 year
      1 yr, 3 months <-> 1 yr, 9 months                                         # => over 1 year
      1 yr, 9 months <-> 2 yr minus 1 sec                                       # => almost 2 years
      2 yrs <-> max time or date                                                # => (same rules as 1 yr)
    
    With <tt>include_seconds: true</tt> and the difference < 1 minute 29 seconds:
      0-4   secs      # => less than 5 seconds
      5-9   secs      # => less than 10 seconds
      10-19 secs      # => less than 20 seconds
      20-39 secs      # => half a minute
      40-59 secs      # => less than a minute
      60-89 secs      # => 1 minute

      YEAR = 365 * 24 * 60 * 20
      MONTH = 30 * 24 * 60 * 20
      DAY = 24 * 60 * 20
      HOUR = 60 * 60
      MINUTE = 60
    
      from_time = Time.now
      distance_of_time_in_words(from_time, from_time + 50*MINUTE)                                # => about 1 hour
      distance_of_time_in_words(from_time, from_time + 15)                                # => less than a minute
      distance_of_time_in_words(from_time, from_time + 15, include_seconds: true)         # => less than 20 seconds
      distance_of_time_in_words(from_time, from_time + 60 * HOUR)                                  # => 3 days
      distance_of_time_in_words(from_time, from_time + 45, include_seconds: true)         # => less than a minute
      distance_of_time_in_words(from_time, from_time 76)                                   # => 1 minute
      distance_of_time_in_words(from_time, from_time + 1*YEAR + 3 * DAY)                           # => about 1 year
      distance_of_time_in_words(from_time, from_time + 3 * YEAR + 6 * MONTH)                        # => over 3 years
      distance_of_time_in_words(from_time, from_time + 4 * YEAR + 9 * DAY + 30 * MINUTE + 5) # => about 4 years
    
      to_time = Time.now + 6 * YEAR + 19 * DAY
      distance_of_time_in_words(from_time, to_time, include_seconds: true)                        # => about 6 years
      distance_of_time_in_words(to_time, from_time, include_seconds: true)                        # => about 6 years
      distance_of_time_in_words(Time.now, Time.now)                                               # => less than a minute
    
    With the <tt>scope</tt> option, you can define a custom scope for Rails
    to look up the translation.
    
    For example you can define the following in your locale (e.g. en.yml).
    
      datetime:
        human:
          distance_in_words:
            short:
              about_x_hours:
                one: "an hour"
                other: "%{count} hours"
    
    See https://github.com/svenfuchs/rails-i18n/blob/master/rails/locale/en.yml
    for more examples.
    
    Which will then result in the following:
    
      from_time = Time.now
      distance_of_time_in_words(from_time, from_time + 50*60)  => "an hour"
      distance_of_time_in_words(from_time, from_time + 3 * 60 * 60)    => "3 hours"')
  DOC
  
  contract(
    Or[Time, DateTime, Date],
    Or[Time, DateTime, Date],
    Ksplat[
      include_seconds?: Bool,
      locale?: Symbol
    ] => String
  ).throws(ArgumentError)
  def call(start_time, end_time, **opts)
    opts = DEFAULT.merge(opts)

    distance_in_minutes = ((end_time.to_time.to_i - start_time.to_time.to_i) / 60.0).round
    distance_in_seconds = (end_time.to_time.to_i - start_time.to_time.to_i).round

    raise ArgumentError, "end_time small than start_time" if distance_in_seconds < 0
    
    case distance_in_minutes
    when 0..1
      return distance_in_minutes == 0 ?
             t('datetime.human.distance_in_words.less_than_x_minutes', count: 1, locale: opts[:locale], default_by_locale: :en) :
             t('datetime.human.distance_in_words.x_minutes', count: distance_in_minutes, locale: opts[:locale], default_by_locale: :en) unless opts[:include_seconds]

      case distance_in_seconds
      when 0..4   then t('datetime.human.distance_in_words.less_than_x_seconds', count: 5, locale: opts[:locale], default_by_locale: :en)
      when 5..9   then t('datetime.human.distance_in_words.less_than_x_seconds', count: 10, locale: opts[:locale], default_by_locale: :en)
      when 10..19 then t('datetime.human.distance_in_words.less_than_x_seconds',count: 20, locale: opts[:locale], default_by_locale: :en)
      when 20..39 then t('datetime.human.distance_in_words.half_a_minute', locale: opts[:locale], default_by_locale: :en)
      when 40..59 then t('datetime.human.distance_in_words.less_than_x_minutes', count: 1, locale: opts[:locale], default_by_locale: :en)
      else             t('datetime.human.distance_in_words.x_minutes', count: 1, locale: opts[:locale], default_by_locale: :en)
      end

    when 2...45           then t('datetime.human.distance_in_words.x_minutes', count: distance_in_minutes, locale: opts[:locale], default_by_locale: :en)
    when 45...90          then t('datetime.human.distance_in_words.about_x_hours', count: 1, locale: opts[:locale], default_by_locale: :en)
      # 90 mins up to 24 hours
    when 90...1440        then t('datetime.human.distance_in_words.about_x_hours',
                                 count: (distance_in_minutes.to_f / 60.0).round, locale: opts[:locale], default_by_locale: :en)
      # 24 hours up to 42 hours
    when 1440...2520      then t('datetime.human.distance_in_words.x_days', count: 1, locale: opts[:locale], default_by_locale: :en)
      # 42 hours up to 30 days
    when 2520...43200     then t('datetime.human.distance_in_words.x_days', count: (distance_in_minutes.to_f / 1440.0).round, locale: opts[:locale], default_by_locale: :en)
      # 30 days up to 60 days
    when 43200...86400    then t('datetime.human.distance_in_words.about_x_months', count: (distance_in_minutes.to_f / 43200.0).round, locale: opts[:locale], default_by_locale: :en)
      # 60 days up to 365 days
    when 86400...525600   then t('datetime.human.distance_in_words.x_months', count: (distance_in_minutes.to_f / 43200.0).round, locale: opts[:locale], default_by_locale: :en)
    else
      start_year = start_time.year
      start_year += 1 if start_time.month >= 3
      end_year = end_time.year
      end_year -= 1 if end_time.month < 3
      leap_years = (start_year > end_year) ? 0 : (start_year..end_year).count { |x| Date.leap?(x) }
      minute_offset_for_leap_year = leap_years * 1440
      # Discount the leap year days when calculating year distance.
      # e.g. if there are 20 leap year days between 2 dates having the same day
      # and month then based on 365 days calculation
      # the distance in years will come out to over 80 years when in written
      # English it would read better as about 80 years.
      minutes_with_offset = distance_in_minutes - minute_offset_for_leap_year
      remainder = (minutes_with_offset % MINUTES_IN_YEAR)
      distance_in_years = (minutes_with_offset.div MINUTES_IN_YEAR)

      if remainder < MINUTES_IN_QUARTER_YEAR
        t('datetime.human.distance_in_words.about_x_years', count: distance_in_years, locale: opts[:locale], default_by_locale: :en)
      elsif remainder < MINUTES_IN_THREE_QUARTERS_YEAR
        t('datetime.human.distance_in_words.over_x_years', count: distance_in_years, locale: opts[:locale], default_by_locale: :en)
      else
        t('datetime.human.distance_in_words.almost_x_years', count: distance_in_years + 1, locale: opts[:locale], default_by_locale: :en)
      end
    end
  end
end