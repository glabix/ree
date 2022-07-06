# frozen_string_literal: true

RSpec.describe :set_locale do
  link :set_locale, from: :ree_i18n
  link :get_locale, from: :ree_i18n
  link :add_load_path, from: :ree_i18n

  it {
    add_load_path(Dir[File.join(__dir__, 'locales/*.yml')])
    
    expect {
      set_locale(:ru)
    }.to_not raise_error

    expect(get_locale()).to eq(:ru)
  }
end