# frozen_string_literal: true

class ReeDatetime::InTimeZone
  include Ree::FnDSL

  fn :in_time_zone do
    link :find_tzinfo
    link :offset_to_string
  end

  doc("Converts current DateTime to time zone of passed +zone+")
  contract(DateTime, String => DateTime)
  def call(date_time, zone)
    new_zone_offset = offset_to_string(
      find_tzinfo(zone).utc_offset
    )
    
    date_time.new_offset(new_zone_offset)
  end
end