# frozen_string_literal: true

class ReeDatetime::TimeAgoInWords
  include Ree::FnDSL

  fn :time_ago_in_words do
    link :distance_of_time_in_words, from: :ree_datetime
    link :now, from: :ree_datetime
  end

  contract(
    Or[DateTime, Time, Date], 
    Ksplat[include_seconds?: Bool] => String).throws(ArgumentError)
  def call(start_time, **opts)
    distance_of_time_in_words(start_time, now, **opts)
  end
end