# frozen_string_literal: true

class ReeDatetime::GetDefaultTzInfo
  include Ree::FnDSL

  fn :get_default_tz_info do
    link :get_default_time_zone
    link :find_tzinfo
  end

  doc("Gets a time zone info according to default time zone")
  contract(None => TZInfo::Timezone)
  def call
    find_tzinfo(get_default_time_zone)
  end
end