# frozen_string_literal: true

class ReeI18n::SetDefaultLocale
  include Ree::FnDSL

  fn :set_default_locale

  contract(Symbol => Symbol).throws(I18n::InvalidLocale)
  def call(locale)
    I18n.default_locale = locale
  end
end