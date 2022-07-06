# frozen_string_literal: true

class ReeDatetime::SetDefaultTimeZone
  include Ree::FnDSL

  fn :set_default_time_zone do
    link :find_tzinfo
  end

  doc("Sets a default time zone (ex. UTC)")
  contract(String => String)
  def call(name)
    tzinfo = find_tzinfo(name)
    Thread.current[:default_time_zone] = tzinfo.name
  end
end