# frozen_string_literal: true

class ReeDatetime::FindTimeZonesByOffset
  include Ree::FnDSL

  fn :find_time_zones_by_offset do
    link :offset_to_string
    link :find_tzinfo
  end

  CACHE = {}

  private_constant :CACHE

  doc("Returns an array of time zone according to the +offset+")
  contract(String => ArrayOf[String])
  def call(offset)
    return CACHE[offset] if CACHE.has_key?(offset)

    zones = TZInfo::Timezone
      .all_identifiers
      .select { |zone| 
         zone_offset = offset_to_string(find_tzinfo(zone).utc_offset)
         zone_offset == offset 
      }

    CACHE[offset] = zones
    zones
  end
end