# frozen_string_literal: true

class ReeDatetime::GetDefaultTimeZone
  include Ree::FnDSL

  fn :get_default_time_zone do
    link 'ree_datetime/functions/constants', -> { DEFAULT_TIME_ZONE }
  end

  doc("Gets a default time zone (ex. UTC)")
  contract(None => String)
  def call
    Thread.current[:default_time_zone] || DEFAULT_TIME_ZONE
  end
end