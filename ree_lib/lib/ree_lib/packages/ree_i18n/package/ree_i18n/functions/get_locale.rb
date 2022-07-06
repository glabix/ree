# frozen_string_literal: true

class ReeI18n::GetLocale
  include Ree::FnDSL

  fn :get_locale

  contract(None => Symbol)
  def call
    I18n.locale
  end
end