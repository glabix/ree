# frozen_string_literal: true

class ReeDatetime::InDefaultTimeZone
  include Ree::FnDSL

  fn :in_default_time_zone do
    link :get_default_time_zone
    link :find_tzinfo
    link :offset_to_string
  end

  doc("Converts current DateTime to default time zone")
  contract(DateTime => DateTime)
  def call(date_time)
    zone = get_default_time_zone

    new_zone_offset = offset_to_string(
      find_tzinfo(zone).utc_offset
    )
    
    date_time.new_offset(new_zone_offset)
  end
end