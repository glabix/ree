# frozen_string_literal: true

class ReeDatetime::HumanZoneOffset
  include Ree::FnDSL

  fn :human_zone_offset do
    link :offset_to_string
    link :find_tzinfo
    link 'ree_datetime/functions/constants', -> { ZONE_HUMAN_NAMES }
  end

  doc("Returns an array of time zones with short names according to the +offset+")
  contract(String => String).throws(ArgumentError)
  def call(human_zone_name)
    if !ZONE_HUMAN_NAMES.has_key?(human_zone_name)
      raise ArgumentError, "invalid human zone name"
    end

    zone = ZONE_HUMAN_NAMES[human_zone_name]
    tzinfo = find_tzinfo(zone)

    offset_to_string(tzinfo.utc_offset)
  end
end