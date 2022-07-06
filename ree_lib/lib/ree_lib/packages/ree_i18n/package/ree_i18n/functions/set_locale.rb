# frozen_string_literal: true

class ReeI18n::SetLocale
  include Ree::FnDSL

  fn :set_locale

  contract(Symbol => Symbol).throws(I18n::InvalidLocale)
  def call(locale)
    I18n.locale = locale
  end
end