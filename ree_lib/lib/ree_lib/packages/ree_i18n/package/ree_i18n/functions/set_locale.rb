# frozen_string_literal: true

class ReeI18n::SetLocale
  include Ree::FnDSL

  fn :set_locale

  contract(Or[Symbol, String] => Symbol).throws(I18n::InvalidLocale)
  def call(locale)
    I18n.locale = locale.to_sym
  end
end