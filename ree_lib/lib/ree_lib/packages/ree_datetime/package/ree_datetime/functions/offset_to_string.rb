# frozen_string_literal: true

class ReeDatetime::OffsetToString
  include Ree::FnDSL

  fn :offset_to_string

  MAX_OFFSET = 86_400
  OFFSET_CACHE = {}

  doc("Converts an offset in seconds to a formatted string (ex. 3600 => '+01:00")
  contract(Integer => String).throws(ArgumentError)
  def call(offset)
    return OFFSET_CACHE[offset] if OFFSET_CACHE.has_key?(offset)

    if !(-MAX_OFFSET..MAX_OFFSET).include?(offset)
      raise ArgumentError, "offset should be in (-#{MAX_OFFSET}..#{MAX_OFFSET})"
    end

    val = offset.abs
    hours = val / 3600
    minutes = (val % 3600) / 60
    str = "#{offset < 0 ? '-' : '+'}#{hours < 10 ? '0' : ''}#{hours}:#{minutes < 10 ? '0' : ''}#{minutes}"

    OFFSET_CACHE[offset] = str
  end
end