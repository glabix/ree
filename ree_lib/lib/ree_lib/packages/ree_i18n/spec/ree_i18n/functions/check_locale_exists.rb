# frozen_string_literal: true

RSpec.describe :check_locale_exists do
  link :set_locale, from: :ree_i18n
  link :get_locale, from: :ree_i18n
  link :add_load_path, from: :ree_i18n

  it {
    add_load_path(Dir[File.join(__dir__, 'locales/*.yml')])

    expect(check_locale_exists("count.zero", "ru")).to eq(true)
    expect(check_locale_exists("count.zero")).to eq(true)
    expect(check_locale_exists("count.zero", :fr)).to eq(false)
    expect(check_locale_exists("count.none", :ru)).to eq(false)
  }
end