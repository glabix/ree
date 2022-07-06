# frozen_string_literal: true

class ReeI18n::GetDefaultLocale
  include Ree::FnDSL

  fn :get_default_locale

  contract(None => Symbol)
  def call
    I18n.default_locale
  end
end