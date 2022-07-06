# frozen_string_literal: true

class ReeDatetime::FindTzinfo
  include Ree::FnDSL

  fn :find_tzinfo do
    link 'ree_datetime/functions/constants', -> { ZONE_HUMAN_NAMES }
  end

  doc("Returns an individual time zone accroding to the +name+ parameter")
  contract(String => TZInfo::Timezone).throws(TZInfo::InvalidTimezoneIdentifier)
  def call(name)
    TZInfo::Timezone.get(ZONE_HUMAN_NAMES[name] || name)
  end
end