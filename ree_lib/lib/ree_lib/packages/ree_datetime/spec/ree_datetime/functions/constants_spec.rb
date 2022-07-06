# frozen_string_literal: true

package_require('ree_datetime/functions/constants')

RSpec.describe ReeDatetime::Constants do
  link :find_tzinfo, from: :ree_datetime

  it {
    ReeDatetime::Constants::ZONE_HUMAN_NAMES.each do |_, zone|
      expect(find_tzinfo(zone)).to be_a(TZInfo::Timezone)
    end
  }
end