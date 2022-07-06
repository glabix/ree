# frozen_string_literal: true

class ReeDatetime::Now
  include Ree::FnDSL

  fn :now do
    link :get_default_tz_info
    link :offset_to_string
  end
  
  doc("Returns a new date/time representing now.")
  contract(None => Exactly[DateTime])
  def call
    tz = get_default_tz_info
    offset = offset_to_string(tz.utc_offset)
    time = DateTime.now

    return time if time.zone == offset
      
    time.new_offset(offset)
  end
end