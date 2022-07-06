# frozen_string_literal: true

class ReeDatetime::ZoneOffset
  include Ree::FnDSL

  fn :zone_offset do
    link :offset_to_string
    link :find_tzinfo
  end

  doc("Returns an array of time zones with short names according to the +offset+")
  contract(String => String)
  def call(zone_name)
    tzinfo = find_tzinfo(zone_name)
    offset_to_string(tzinfo.utc_offset)
  end
end