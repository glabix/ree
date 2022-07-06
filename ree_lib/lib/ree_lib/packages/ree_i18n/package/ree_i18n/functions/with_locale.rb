# frozen_string_literal: true

class ReeI18n::WithLocale
  include Ree::FnDSL

  fn :with_locale

  contract(Symbol, Block => nil)
  def call(paths, &block)
    I18n.with_locale(locale, &block)
  end
end