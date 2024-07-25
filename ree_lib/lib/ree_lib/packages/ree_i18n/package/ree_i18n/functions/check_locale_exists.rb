# frozen_string_literal: true

class ReeI18n::CheckLocaleExists
  include Ree::FnDSL

  fn :check_locale_exists

  contract(String, Nilor[Or[String, Symbol]] => Bool)
  def call(value, locale = nil)
    I18n.exists?(value, locale || I18n.default_locale)
  end
end