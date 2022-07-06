# frozen_string_literal: true

require 'set'

class ReeDatetime::FindHumanTimeZonesByOffset
  include Ree::FnDSL

  fn :find_human_time_zones_by_offset do
    link :find_time_zones_by_offset
    link 'ree_datetime/functions/constants', -> { ZONE_HUMAN_NAMES }
  end

  ALL_ZONES = Set.new(ZONE_HUMAN_NAMES.values)
  INVERTED_ZONES = ZONE_HUMAN_NAMES.invert
  CACHE = {}

  private_constant :CACHE

  doc("Returns an array of time zones with short names according to the +offset+")
  contract(String => ArrayOf[String])
  def call(offset)
    return CACHE[offset] if CACHE.has_key?(offset)

    human_zones = find_time_zones_by_offset(offset)
      .select { ALL_ZONES.include?(_1) }
      .map { INVERTED_ZONES[_1] }

    CACHE[offset] = human_zones
    human_zones
  end
end